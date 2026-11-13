# Maintenance of a shared environment, such as a water change (EN04, D121–D123). One event
# for the environment, linked to the plants in it when it happened; it's never copied per
# plant. The client's idempotency key makes retries and offline syncs safe (OF02, D126).
class EnvironmentEvent < ApplicationRecord
  KINDS = %w[ water_change top_up filter_clean dosing substrate_vacuum glass_clean misting_check ventilation_check equipment_check light_check custom ].freeze

  # The kinds each environment type shows first (D121); the rest sit under More.
  FEATURED = {
    "aquarium" => %w[ water_change top_up filter_clean dosing ],
    "paludarium" => %w[ misting_check ventilation_check glass_clean water_change ],
    "terrarium" => %w[ misting_check ventilation_check glass_clean ],
    "grow_cabinet" => %w[ ventilation_check light_check equipment_check ],
    "room_shelf" => %w[ light_check equipment_check ],
    "acclimatisation" => %w[ ventilation_check misting_check ],
    "outdoor_bed" => %w[ equipment_check ]
  }.freeze

  AMOUNT_UNITS = {
    "water_change" => %w[ % L ],
    "top_up" => %w[ L mL ],
    "dosing" => %w[ mL g drops ]
  }.freeze
  # The details each kind keeps; others are dropped before saving.
  DETAILS = {
    "water_change" => %i[ amount amount_unit ],
    "top_up" => %i[ amount amount_unit ],
    "dosing" => %i[ product amount amount_unit ],
    "custom" => %i[ label ]
  }.freeze
  DETAIL_COLUMNS = %i[ amount amount_unit product label ].freeze

  belongs_to :user
  belongs_to :environment
  belongs_to :care_task, optional: true
  has_many :event_plants, class_name: "EnvironmentEventPlant", dependent: :delete_all
  has_many :plants, through: :event_plants
  has_many :photos, -> { order(:id) }, dependent: :destroy

  normalizes :product, :label, with: ->(value) { value.squish.presence }

  before_validation :drop_unused_details

  validates :kind, inclusion: { in: KINDS }
  validates :occurred_at, :idempotency_key, presence: true
  validates :idempotency_key, length: { maximum: 64 }, uniqueness: { scope: :user_id }
  validates :note, length: { maximum: 5000 }
  validates :product, length: { maximum: 120 }
  validates :label, length: { maximum: 80 }
  validates :label, presence: { message: "can't be blank for your own kind of maintenance" }, if: :custom?
  validates :amount, numericality: { greater_than: 0, less_than: 10_000_000 }, allow_nil: true
  validates :amount, numericality: { less_than_or_equal_to: 100, message: "can't be more than 100%" }, if: -> { amount && amount_unit == "%" }
  validates :amount_unit, inclusion: { in: ->(event) { AMOUNT_UNITS.fetch(event.kind, []) } }, allow_nil: true
  validates :amount_unit, presence: { message: "is needed with an amount" }, if: :amount
  validate :environment_belongs_to_user

  after_save :link_plants_present, if: :saved_change_to_occurred_at?
  after_create :complete_open_task, if: -> { care_task_id.nil? }
  after_destroy -> { care_task.reopen! }, if: -> { care_task&.completed? && !destroyed_by_association }

  scope :newest_first, -> { order(occurred_at: :desc, id: :desc) }

  def custom? = kind == "custom"
  def water_change? = kind == "water_change"

  def self.featured_kinds(environment) = FEATURED.fetch(environment.kind, [])
  def self.other_kinds(environment) = KINDS - featured_kinds(environment)

  # Earlier dosing products and custom labels, latest first (D105, D121).
  def self.suggestions_for(user)
    %i[ product label ].index_with do |column|
      user.environment_events.where.not(column => nil).group(column).order(Arel.sql("MAX(occurred_at) DESC")).limit(30).pluck(column)
    end
  end

  private
    # Logging maintenance completes the environment's matching reminder that's due or nearly
    # due, like plant care does (D114, D125).
    def complete_open_task
      date = occurred_at.to_date
      task = environment.care_tasks.open.where(due_on: ..(date + CareTask::EARLY_DAYS)).includes(:care_schedule).order(:due_on, :id)
        .find { it.care_schedule.matches?(kind, label) }
      return unless task

      self.care_task = task
      task.resolve_with!(self)
    end

    # The plants in the environment on the day it happened (D123), again if the date changes.
    def link_plants_present
      date = occurred_at.to_date
      ids = environment.assignments.where(started_on: ..date).where("ended_on IS NULL OR ended_on > ?", date).pluck(:plant_id)
      event_plants.delete_all
      EnvironmentEventPlant.insert_all(ids.map { { environment_event_id: id, plant_id: it } }) if ids.any?
      association(:plants).reset
    end

    def drop_unused_details
      kept = DETAILS.fetch(kind, [])
      (DETAIL_COLUMNS - kept).each { self[it] = nil }
      self.amount_unit = nil if amount.nil?
    end

    def environment_belongs_to_user
      errors.add(:environment, "must be yours") if environment && environment.user_id != user_id
    end
end
