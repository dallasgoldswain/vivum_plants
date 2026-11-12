# How a plant is potted and watered from a date on (PL05, D89). The newest setup is current;
# earlier ones stay so older timeline entries show the setup at the time. A setup can name
# the exact recipe version the plant was potted in (SU04, D100).
class PlantSetup < ApplicationRecord
  SIZE_UNITS = %w[ cm L ].freeze
  WATERING_METHODS = %w[ top bottom self_watering wick semi_hydro submerged misting ].freeze

  belongs_to :user
  belongs_to :plant
  belongs_to :recipe_version, optional: true

  enum :watering_method, WATERING_METHODS.index_by(&:itself), validate: { allow_nil: true }, prefix: :watered

  normalizes :container, with: ->(value) { value.squish.presence }

  validates :started_on, presence: true
  validates :container, length: { maximum: 80 }
  validates :size, numericality: { greater_than: 0, less_than: 100_000 }, allow_nil: true
  validates :size_unit, inclusion: { in: SIZE_UNITS }, if: :size
  validate :something_recorded
  validate :same_owner
  validate :recipe_version_ready

  before_validation { self.size_unit = nil unless size }

  scope :chronological, -> { order(:started_on, :id) }
  # Each plant's newest setup.
  scope :current, -> { where(id: unscoped.select("DISTINCT ON (plant_id) id").order(:plant_id, started_on: :desc, id: :desc)) }

  private
    def something_recorded
      errors.add(:base, "Add a container, size, watering method or recipe") if container.blank? && size.blank? && watering_method.blank? && recipe_version.nil?
    end

    def same_owner
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
      errors.add(:recipe_version, "must be one of your recipes") if recipe_version && recipe_version.recipe.user_id != user_id
    end

    # Only a ready version can be given to a plant (D99). Once given, it stays.
    def recipe_version_ready
      errors.add(:recipe_version, "is still a draft") if recipe_version && recipe_version_id_changed? && !recipe_version.ready?
    end
end
