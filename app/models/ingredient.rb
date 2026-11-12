# A substrate ingredient (SU01, D96, D97). Built-ins have no user, come from
# db/seeds/ingredients.yml and can't be edited; a collector copies one to change it.
# Personal ingredients can be generic or branded (with a manufacturer).
class Ingredient < ApplicationRecord
  CATEGORIES = %w[ bark mineral aggregate fibre moss organic charcoal amendment aquatic other ].freeze
  LEVELS = %w[ low medium high ].freeze
  STATUSES = %w[ active archived ].freeze
  BUILT_INS = Rails.root.join("db/seeds/ingredients.yml")

  belongs_to :user, optional: true
  belongs_to :copied_from, class_name: "Ingredient", optional: true
  has_many :components, class_name: "RecipeComponent", dependent: :restrict_with_error

  enum :category, CATEGORIES.index_by(&:itself), validate: true
  enum :water_retention, LEVELS.index_by(&:itself), validate: { allow_nil: true }, prefix: :retention
  enum :aeration, LEVELS.index_by(&:itself), validate: { allow_nil: true }, prefix: :aeration
  enum :status, STATUSES.index_by(&:itself), validate: true, default: "active"

  normalizes :name, :manufacturer, :source, with: ->(value) { value.squish.presence }

  validates :name, presence: true, length: { maximum: 80 }
  validates :manufacturer, :source, length: { maximum: 120 }
  validates :intended_use, :preparation, length: { maximum: 2000 }
  validates :notes, length: { maximum: 5000 }
  validates :particle_min_mm, :particle_max_mm, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  validate :particle_range_in_order

  scope :built_in, -> { where(user_id: nil) }
  scope :personal, -> { where.not(user_id: nil) }
  scope :visible_to, ->(user) { where(user_id: [ nil, user.id ]) }
  scope :by_name, -> { order(Arel.sql("lower(ingredients.name)"), Arel.sql("lower(coalesce(ingredients.manufacturer, ''))"), :id) }
  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.squish)}%"
    query.present? ? where("ingredients.name ILIKE :term OR ingredients.manufacturer ILIKE :term", term: term) : all
  }

  # Creates or updates the built-ins from the YAML seed, matched by key (D96). Safe to run
  # on every deploy; built-ins removed from the file are archived, never deleted, so recipes
  # that use them keep working.
  def self.sync_built_ins!
    entries = YAML.safe_load_file(BUILT_INS)
    transaction do
      entries.each do |key, attributes|
        built_in.find_or_initialize_by(key: key).update!(attributes.merge("status" => "active"))
      end
      built_in.where.not(key: entries.keys).update_all(status: "archived", updated_at: Time.current)
    end
  end

  def built_in? = user_id.nil?
  def branded? = manufacturer.present?
  def used? = components.exists?

  # "Orchid bark" or "Pumice (Kiwi Pumice)"
  def label = branded? ? "#{name} (#{manufacturer})" : name

  # A personal copy of a built-in, to edit (D96).
  def copy_for!(user)
    user.ingredients.create!(
      attributes.slice(*%w[ name category water_retention aeration particle_min_mm particle_max_mm intended_use preparation source notes ]).merge(copied_from: self)
    )
  end

  private
    def particle_range_in_order
      return unless particle_min_mm && particle_max_mm && particle_min_mm > particle_max_mm

      errors.add(:particle_max_mm, "must be at least the smallest size")
    end
end
