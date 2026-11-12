# A plant in a collector's personal collection (PL01–PL03, D80–D87). Only a display name
# and growing context are required; identity can stay unknown and names can repeat.
class Plant < ApplicationRecord
  GROWING_CONTEXTS = %w[ indoor terrarium paludarium aquatic outdoor ].freeze
  STATUSES = %w[ active quarantined lost sold gifted archived ].freeze
  ACTIVE_STATUSES = %w[ active quarantined ].freeze
  TAG_LIMIT = 20

  include Searchable
  include Placement

  belongs_to :user
  belongs_to :acquisition, optional: true
  belongs_to :cover_photo, class_name: "Photo", optional: true
  has_many :status_changes, -> { order(:effective_on, :created_at) }, class_name: "PlantStatusChange", dependent: :delete_all
  has_many :care_events, dependent: :destroy
  has_many :photos, dependent: :destroy

  accepts_nested_attributes_for :acquisition, reject_if: :acquisition_blank?

  enum :growing_context, GROWING_CONTEXTS.index_by(&:itself), validate: true
  enum :status, STATUSES.index_by(&:itself), validate: true, default: "active"

  normalizes :display_name, :botanical_name, :cultivar, :common_name, :nickname, :origin_note, with: ->(value) { value.strip.presence }

  validates :display_name, presence: true, length: { maximum: 120 }
  validates :botanical_name, :cultivar, :common_name, :nickname, length: { maximum: 120 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :tags, length: { maximum: TAG_LIMIT, message: "can't be more than %{count}" }
  validate :linked_records_share_owner

  before_validation { acquisition.user ||= user if acquisition }
  before_create :assign_number
  after_destroy :remove_orphaned_acquisition
  after_create :record_initial_status

  scope :in_active_collection, -> { where(status: ACTIVE_STATUSES) }
  scope :inactive, -> { where.not(status: ACTIVE_STATUSES) }

  # Tags are typed as one comma-separated field (D85), stored lower-case and unique.
  def tag_list = tags.join(", ")

  def tag_list=(value)
    self.tags = value.to_s.split(",").map { it.squish.downcase }.compact_blank.uniq
  end

  def record_id = format("P-%04d", number)
  def to_param = id.to_s
  def active? = ACTIVE_STATUSES.include?(status)

  # Status with an effective date and reason, kept as history (PL03).
  def change_status!(new_status, on: Date.current, reason: nil)
    transaction do
      update!(status: new_status, status_on: on)
      status_changes.create!(status: new_status, effective_on: on, reason: reason.presence)
    end
  end

  # Newest first: observations, status changes and photos added on their own (PL04).
  def timeline
    entries = care_events.includes(:environment, :from_environment, :plant_setup, photos: { image_attachment: :blob }).map { Timeline::Entry.new(it.kind.to_sym, it.occurred_at, it) }
    entries += status_changes.map { Timeline::Entry.new(:status_change, it.effective_on.in_time_zone.end_of_day, it) }
    entries += photos.standalone.with_attached_image.map { Timeline::Entry.new(:photo, it.taken_on.in_time_zone.end_of_day, it) }
    entries.sort_by { [ -it.at.to_f, -it.record.created_at.to_f ] }
  end

  # What a permanent delete removes (D86).
  def deletion_effects
    { photos: photos.count, observations: care_events.observation.count, moves: environment_assignments.size, setups: setups.size, status_changes: status_changes.count }
  end

  module Timeline
    Entry = Data.define(:kind, :at, :record)
  end

  private
    def assign_number
      self.number ||= user.next_plant_number!
    end

    def record_initial_status
      status_changes.create!(status: status, effective_on: status_on || created_at.to_date, reason: "Added to collection")
    end

    def remove_orphaned_acquisition
      acquisition.destroy! if acquisition && !acquisition.plants.exists?
    end

    def acquisition_blank?(attributes)
      attributes.except("id", "currency", "_destroy").values.all?(&:blank?)
    end

    def linked_records_share_owner
      errors.add(:acquisition, "must be yours") if acquisition && acquisition.user_id != user_id
      errors.add(:cover_photo, "must be a photo of this plant") if cover_photo && cover_photo.plant_id != id
    end
end
