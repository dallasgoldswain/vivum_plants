# A dated photo of a plant, on its own or attached to a timeline event (PL04, OF03, D83).
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
  belongs_to :plant
  belongs_to :care_event, optional: true

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 480, 480 ], format: :jpeg, saver: { quality: 80, strip: true }, preprocessed: true
    attachable.variant :large, resize_to_limit: [ 1400, 1400 ], format: :jpeg, saver: { quality: 82, strip: true }, preprocessed: true
  end

  validates :caption, length: { maximum: 200 }
  validates :taken_on, presence: true
  validate :image_attached
  validate :same_owner

  after_create :become_cover_if_none

  scope :standalone, -> { where(care_event_id: nil) }
  scope :newest_first, -> { order(taken_on: :desc, id: :desc) }

  # The quota (OF03): collectors keep up to 500 photos; deleting photos frees space.
  def self.quota_for(user)
    Quota.new(used: user.photos.count, limit: COLLECTOR_LIMIT)
  end

  Quota = Data.define(:used, :limit) do
    def remaining = [ limit - used, 0 ].max
    def full? = used >= limit
    def warning? = used >= (limit * WARN_AT).ceil
  end

  # Builds a processed photo from an uploaded file, or raises Rejected with a reason the
  # collector can read. Never stores the original.
  def self.build_from_upload(upload, user:, plant:, care_event: nil, caption: nil, taken_on: nil)
    raise Rejected, "You've reached your #{COLLECTOR_LIMIT} photos. Delete some to add more." if quota_for(user).full?
    raise Rejected, "Choose a JPEG, PNG or WebP photo." unless ACCEPTED_TYPES.include?(Marcel::MimeType.for(upload.tempfile))
    raise Rejected, "That photo is over #{MAX_UPLOAD_SIZE / 1.megabyte} MB." if upload.size > MAX_UPLOAD_SIZE

    processed = process(upload.tempfile.path)
    new(user: user, plant: plant, care_event: care_event, caption: caption.presence, taken_on: taken_on.presence || care_event&.occurred_at&.to_date || Date.current).tap do |photo|
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

  def cover? = plant.cover_photo_id == id

  private
    def become_cover_if_none
      plant.update_column(:cover_photo_id, id) unless plant.cover_photo_id
    end

    def image_attached
      errors.add(:image, "is missing") unless image.attached?
    end

    def same_owner
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
      errors.add(:care_event, "must be on this plant") if care_event && care_event.plant_id != plant_id
    end
end
