# A dated photo of a plant (on its own or with a timeline event) or of an environment
# (PL04, OF03, D83, D94).
# Uploads are processed before storage: rotated upright, resized to 2560 px on the long edge
# and stripped of all metadata, including location. Thumbnails are variants.
class Photo < ApplicationRecord
  COLLECTOR_LIMIT = 500
  WARN_AT = 0.8
  MAX_UPLOAD_SIZE = 25.megabytes
  LONG_EDGE = 2560
  ACCEPTED_TYPES = %w[ image/jpeg image/png image/webp ].freeze

  class Rejected < StandardError; end

  belongs_to :user
  belongs_to :plant, optional: true
  belongs_to :environment, optional: true
  belongs_to :care_event, optional: true
  belongs_to :environment_event, optional: true
  belongs_to :acquisition, optional: true
  belongs_to :stock_item, optional: true

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 480, 480 ], format: :jpeg, saver: { quality: 80, strip: true }, preprocessed: true
    attachable.variant :large, resize_to_limit: [ 1400, 1400 ], format: :jpeg, saver: { quality: 82, strip: true }, preprocessed: true
  end

  validates :caption, length: { maximum: 200 }
  validates :taken_on, presence: true
  validate :image_attached
  validate :same_owner

  after_create :become_cover_if_none

  scope :standalone, -> { where(care_event_id: nil, environment_event_id: nil) }
  scope :newest_first, -> { order(taken_on: :desc, id: :desc) }

  # The quota (OF03): collectors keep up to 500 photos; deleting photos frees space.
  def self.quota_for(user)
    Quota.new(used: user.photos.where(stock_item_id: nil).count, limit: COLLECTOR_LIMIT)
  end

  # Stock photos count against the seller's plan, not the member who added them (D163).
  def self.quota_for_seller(seller)
    Quota.new(used: joins(:stock_item).where(stock_items: { seller_id: seller.id }).count, limit: seller.plan.photo_limit)
  end

  Quota = Data.define(:used, :limit) do
    def remaining = [ limit - used, 0 ].max
    def full? = used >= limit
    def warning? = used >= (limit * WARN_AT).ceil
  end

  # Builds a processed photo from an uploaded file, or raises Rejected with a reason the
  # collector can read. Never stores the original.
  def self.build_from_upload(upload, user:, plant: nil, environment: nil, acquisition: nil, stock_item: nil, care_event: nil, environment_event: nil, caption: nil, taken_on: nil)
    if stock_item
      raise Rejected, "Your business has reached its #{quota_for_seller(stock_item.seller).limit} photos. Delete some to add more." if quota_for_seller(stock_item.seller).full?
    elsif quota_for(user).full?
      raise Rejected, "You've reached your #{COLLECTOR_LIMIT} photos. Delete some to add more."
    end
    raise Rejected, "Choose a JPEG, PNG or WebP photo." unless ACCEPTED_TYPES.include?(Marcel::MimeType.for(upload.tempfile))
    raise Rejected, "That photo is over #{MAX_UPLOAD_SIZE / 1.megabyte} MB." if upload.size > MAX_UPLOAD_SIZE

    processed = process(upload.tempfile.path)
    new(user: user, plant: plant, environment: environment, acquisition: acquisition, stock_item: stock_item, care_event: care_event, environment_event: environment_event, caption: caption.presence, taken_on: taken_on.presence || (care_event || environment_event)&.occurred_at&.to_date || Date.current).tap do |photo|
      photo.image.attach(io: File.open(processed.path), filename: "#{File.basename(upload.original_filename.to_s, '.*').parameterize.presence || 'photo'}.jpg", content_type: "image/jpeg")
    end
  rescue Vips::Error
    raise Rejected, "That file couldn't be read as a photo."
  end

  def self.process(path)
    ImageProcessing::Vips.source(path)
      .autorot
      .resize_to_limit(LONG_EDGE, LONG_EDGE)
      .custom { |image| image.has_alpha? ? image.flatten(background: [ 255, 255, 255 ]) : image }
      .convert("jpg")
      .saver(quality: 85, strip: true)
      .call
  end

  def subject = plant || environment || acquisition || stock_item
  def cover? = subject.cover_photo_id == id

  private
    def become_cover_if_none
      subject.update_column(:cover_photo_id, id) unless subject.cover_photo_id
    end

    def image_attached
      errors.add(:image, "is missing") unless image.attached?
    end

    def same_owner
      errors.add(:base, "A photo belongs to one plant, environment, purchase or stock item") unless [ plant, environment, acquisition, stock_item ].compact.one?
      errors.add(:stock_item, "must be in a business you belong to") if stock_item && !user.memberships.exists?(seller_id: stock_item.seller_id)
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
      errors.add(:environment, "must be yours") if environment && environment.user_id != user_id
      errors.add(:acquisition, "must be yours") if acquisition && acquisition.user_id != user_id
      errors.add(:care_event, "must be on this plant") if care_event && care_event.plant_id != plant_id
    end
end
