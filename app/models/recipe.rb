# A named substrate recipe with numbered versions (SU02, SU04, D98, D99). Setups point at an
# exact version, so changing a version a setup uses saves the next one instead; past repots
# never change. A single-material substrate is a one-ingredient recipe.
class Recipe < ApplicationRecord
  STATUSES = %w[ active archived ].freeze

  belongs_to :user
  has_many :versions, -> { order(:number) }, class_name: "RecipeVersion", inverse_of: :recipe, dependent: :destroy
  has_many :setups, through: :versions

  enum :status, STATUSES.index_by(&:itself), validate: true, default: "active"

  normalizes :name, :source, with: ->(value) { value.squish.presence }
  normalizes :contexts, with: ->(values) { Array(values).compact_blank.uniq & Plant::GROWING_CONTEXTS }

  validates :name, presence: true, length: { maximum: 80 }
  validates :source, length: { maximum: 200 }
  validates :notes, length: { maximum: 5000 }

  scope :by_name, -> { order(Arel.sql("lower(recipes.name)"), :id) }
  scope :for_context, ->(context) { context.present? ? where("? = ANY(recipes.contexts)", context) : all }
  scope :search, ->(query) {
    next all if query.blank?

    term = "%#{sanitize_sql_like(query.to_s.squish)}%"
    with_ingredient = RecipeVersion.joins(components: :ingredient).where("ingredients.name ILIKE :term OR ingredients.manufacturer ILIKE :term", term: term).select(:recipe_id)
    where("recipes.name ILIKE ?", term).or(where(id: with_ingredient))
  }
  # In use now: a version is the current setup of a plant in the active collection (SU05).
  scope :in_use_now, -> { where(id: RecipeVersion.where(id: PlantSetup.current.where(plant_id: Plant.in_active_collection.select(:id)).select(:recipe_version_id)).select(:recipe_id)) }
  scope :ever_used, -> { where(id: RecipeVersion.where(id: PlantSetup.select(:recipe_version_id)).select(:recipe_id)) }
  scope :by_use, ->(use) {
    case use
    when "now" then in_use_now
    when "before" then ever_used.where.not(id: in_use_now.select(:id))
    when "never" then where.not(id: ever_used.select(:id))
    else all
    end
  }

  def current_version = versions.last
  def latest_ready_version = versions.select(&:ready?).last
  def used? = setups.exists?

  # The version a change is saved to (D99): the current one when no setup uses it, otherwise
  # the next number. Nothing new is built when an in-use version is saved unchanged.
  def build_revision(basis:, notes:, components:, ready:)
    base = current_version
    if base && !base.in_use?
      base.assign_composition(basis:, notes:, components:, ready:)
    else
      version = versions.build(number: (base&.number || 0) + 1)
      version.assign_composition(basis:, notes:, components:, ready:)
      if base && version.same_composition_as?(base)
        versions.target.delete(version)
        return base
      end

      version
    end
  end

  def save_revision(version)
    return false unless [ valid?, version.valid? ].all?

    transaction do
      save!
      version.save!
    end
    true
  end

  # Archiving keeps history and hides the recipe from the setup picker (D101).
  def deletable? = !used?

  # A public, revocable link (D102). Making a new one turns the old one off.
  def share! = update!(share_token: SecureRandom.base58(24))
  def unshare! = update!(share_token: nil)
  def shared? = share_token.present?
end
