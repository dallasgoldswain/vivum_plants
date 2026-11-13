# Where plants grow: a room or shelf, cabinet, tank or bed in a collector's personal
# collection (EN01, D88). Only a name and type are required; environments don't nest.
class Environment < ApplicationRecord
  KINDS = %w[ room_shelf grow_cabinet terrarium paludarium aquarium acclimatisation outdoor_bed ].freeze
  STATUSES = %w[ active archived ].freeze

  # The growing context a type implies, offered when a plant moves in (D91).
  # An acclimatisation container is temporary, so it suggests nothing.
  SUGGESTED_CONTEXTS = {
    "room_shelf" => "indoor", "grow_cabinet" => "indoor", "terrarium" => "terrarium",
    "paludarium" => "paludarium", "aquarium" => "aquatic", "outdoor_bed" => "outdoor"
  }.freeze

  class NotArchivable < StandardError; end

  belongs_to :user
  belongs_to :cover_photo, class_name: "Photo", optional: true
  has_many :assignments, class_name: "EnvironmentAssignment", dependent: :restrict_with_error
  has_many :current_assignments, -> { current }, class_name: "EnvironmentAssignment"
  has_many :current_plants, through: :current_assignments, source: :plant
  has_many :measurements, dependent: :destroy
  has_many :photos, dependent: :destroy
  has_many :maintenance_events, class_name: "EnvironmentEvent", dependent: :destroy
  has_many :care_schedules, dependent: :destroy
  has_many :care_tasks

  enum :kind, KINDS.index_by(&:itself), validate: true
  enum :status, STATUSES.index_by(&:itself), validate: true, default: "active"

  normalizes :name, with: ->(value) { value.squish.presence }

  validates :name, presence: true, length: { maximum: 80 }
  validates :notes, length: { maximum: 5000 }
  validates :length_cm, :width_cm, :height_cm, :volume_litres, numericality: { greater_than: 0, less_than: 1_000_000 }, allow_nil: true
  validate :cover_photo_is_ours

  scope :by_name, -> { order(Arel.sql("lower(environments.name)"), :id) }

  def suggested_context = SUGGESTED_CONTEXTS[kind]

  # Archiving keeps history and hides the environment from pickers (D95). Its plants have to
  # move out first, so no plant is left in an environment nobody can see.
  def archive!
    raise NotArchivable, "Move or remove its plants first." if current_assignments.exists?

    transaction do
      update!(status: "archived")
      care_schedules.running.each { it.pause!(by_status: true) }
    end
  end

  # Restoring resumes the reminders archiving paused, from today (D125).
  def restore!
    transaction do
      update!(status: "active")
      care_schedules.paused.where(paused_by_status: true).each(&:resume!)
    end
  end

  # Permanent delete is only for an environment that has never held a plant (D95).
  def deletable? = !assignments.exists?

  def deletion_effects
    { measurements: measurements.count, photos: photos.count, maintenance: maintenance_events.count, reminders: care_schedules.where.not(status: "ended").count }
  end

  # The most recent value of each metric, with the reading it came from (EN02).
  def latest_values
    MeasurementValue.joins(:measurement).where(measurements: { environment_id: id })
      .select("DISTINCT ON (measurement_values.metric, measurement_values.custom_metric_id) measurement_values.*")
      .order("measurement_values.metric, measurement_values.custom_metric_id, measurements.measured_at DESC, measurements.id DESC")
      .includes(:measurement, :custom_metric)
      .sort_by { [ Measurement::METRICS.keys.index(it.metric) || Measurement::METRICS.size, it.custom_metric&.name.to_s.downcase ] }
  end

  private
    def cover_photo_is_ours
      errors.add(:cover_photo, "must be a photo of this environment") if cover_photo && cover_photo.environment_id != id
    end
end
