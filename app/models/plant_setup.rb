# How a plant is potted and watered from a date on (PL05, D89). The newest setup is current;
# earlier ones stay so older timeline entries show the setup at the time. Recipe version
# joins with substrates (B12).
class PlantSetup < ApplicationRecord
  SIZE_UNITS = %w[ cm L ].freeze
  WATERING_METHODS = %w[ top bottom self_watering wick semi_hydro submerged misting ].freeze

  belongs_to :user
  belongs_to :plant

  enum :watering_method, WATERING_METHODS.index_by(&:itself), validate: { allow_nil: true }, prefix: :watered

  normalizes :container, with: ->(value) { value.squish.presence }

  validates :started_on, presence: true
  validates :container, length: { maximum: 80 }
  validates :size, numericality: { greater_than: 0, less_than: 100_000 }, allow_nil: true
  validates :size_unit, inclusion: { in: SIZE_UNITS }, if: :size
  validate :something_recorded
  validate :same_owner

  before_validation { self.size_unit = nil unless size }

  scope :chronological, -> { order(:started_on, :id) }

  private
    def something_recorded
      errors.add(:base, "Add a container, size or watering method") if container.blank? && size.blank? && watering_method.blank?
    end

    def same_owner
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
    end
end
