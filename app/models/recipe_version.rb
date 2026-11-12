# One numbered composition of a recipe: ingredients and quantities in parts or % by volume
# (SU02, SU04, D98, D99). A draft can't be given to a plant; a % version must total 100%
# before it's ready.
class RecipeVersion < ApplicationRecord
  BASES = %w[ parts percent ].freeze
  STATES = %w[ draft ready ].freeze

  belongs_to :recipe, inverse_of: :versions
  has_many :components, -> { order(:position, :id) }, class_name: "RecipeComponent", inverse_of: :recipe_version, autosave: true, dependent: :destroy
  has_many :setups, class_name: "PlantSetup", dependent: :restrict_with_error

  enum :basis, BASES.index_by(&:itself), validate: true
  enum :state, STATES.index_by(&:itself), validate: true, default: "draft"

  validates :notes, length: { maximum: 5000 }
  validate :has_components
  validate :ingredients_once_each
  validate :ingredients_are_ours
  validate :percent_totals_100, if: -> { ready? && percent? }

  def label = "v#{number}"
  def in_use? = persisted? && setups.exists?
  def kept_components = components.reject(&:marked_for_destruction?)
  def total = kept_components.sum(&:quantity)

  # Each component's share of the mix, 0–1.
  def fraction_for(component) = total.positive? ? component.quantity / total : 0

  # Replaces the components and settings with what the form sent. Rows without an
  # ingredient are ignored.
  def assign_composition(basis:, notes:, components:, ready:)
    self.basis = basis
    self.notes = notes.presence
    self.state = ready ? "ready" : "draft"
    self.components.each(&:mark_for_destruction)
    Array(components).each_with_index do |row, index|
      next if row[:ingredient_id].blank?

      self.components.build(ingredient_id: row[:ingredient_id], quantity: row[:quantity].presence, position: index)
    end
    self
  end

  def same_composition_as?(other)
    signature == other.signature
  end

  protected
    def signature
      [ basis, state, notes, kept_components.map { [ it.ingredient_id.to_i, it.quantity&.to_d ] }.sort ]
    end

  private
    def has_components
      errors.add(:base, "Add at least one ingredient") if kept_components.empty?
    end

    def ingredients_once_each
      ids = kept_components.map { it.ingredient_id.to_i }
      errors.add(:base, "Each ingredient can only be listed once") if ids.uniq.size < ids.size
    end

    def ingredients_are_ours
      ids = kept_components.map(&:ingredient_id).compact
      allowed = Ingredient.visible_to(recipe.user).where(id: ids).count
      errors.add(:base, "Choose ingredients from your list") if allowed < ids.uniq.size
    end

    def percent_totals_100
      return if total == 100

      errors.add(:base, "Percentages add up to #{total.to_s('F').delete_suffix('.0')}%; they need to total 100% before the recipe is ready")
    end
end
