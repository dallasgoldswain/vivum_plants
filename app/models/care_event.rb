# An entry on a plant's timeline (D82): observations, logged care (CA01, D104), and moves
# and setup changes (D92). The event date is when it happened, separate from when it was
# entered (PL04). The client's idempotency key makes retries and offline syncs safe (OF02).
class CareEvent < ApplicationRecord
  # What a collector logs from the care buttons (D103); every detail is optional.
  LOGGED_KINDS = %w[ watering feeding repotting pruning treatment inspection custom ].freeze
  # Written by moves and setup changes; they mirror that history, so they're never edited (D108).
  # Stage changes and splits mirror the plant's TC stage and split history the same way (D128, D133).
  PLACEMENT_KINDS = %w[ movement setup stage splitting ].freeze
  KINDS = ([ "observation" ] + LOGGED_KINDS + PLACEMENT_KINDS).freeze
  # Kinds the "last care" summary reports (D109).
  SUMMARY_KINDS = %w[ watering feeding repotting treatment ].freeze

  WATERING_METHODS = %w[ top bottom soak mist ].freeze
  STRENGTHS = %w[ full half quarter ].freeze
  # Which units an amount can have, by kind: a watering's volume, or a product's dose.
  AMOUNT_UNITS = {
    "watering" => %w[ mL L ],
    "feeding" => %w[ mL/L g/L mL g drops ],
    "treatment" => %w[ mL/L g/L mL g drops ]
  }.freeze
  # The details each kind keeps; others are dropped before saving.
  DETAILS = {
    "watering" => %i[ amount amount_unit watering_method ],
    "feeding" => %i[ product amount amount_unit strength ],
    "treatment" => %i[ product target amount amount_unit ],
    "custom" => %i[ label ],
    # A TC check is an inspection with progress ticks; never a diagnosis (TC03, D129).
    "inspection" => %i[ new_leaves new_roots damage suspected_contamination humidity_setup ]
  }.freeze
  TC_CHECK_TICKS = %i[ new_leaves new_roots damage suspected_contamination ].freeze
  DETAIL_COLUMNS = (%i[ amount amount_unit watering_method product strength target label humidity_setup ] + TC_CHECK_TICKS).freeze

  belongs_to :user
  belongs_to :plant
  belongs_to :environment, optional: true
  belongs_to :from_environment, class_name: "Environment", optional: true
  belongs_to :plant_setup, optional: true
  belongs_to :care_task, optional: true
  has_many :photos, -> { order(:id) }, dependent: :destroy

  enum :kind, KINDS.index_by(&:itself), validate: true, default: "observation"

  normalizes :product, :target, :label, :humidity_setup, with: ->(value) { value.squish.presence }

  before_validation :drop_unused_details
  after_create :complete_open_task, if: -> { care_task_id.nil? && kind.in?(LOGGED_KINDS) }
  after_destroy -> { care_task.reopen! }, if: -> { care_task&.completed? && !destroyed_by_association }

  validates :occurred_at, :idempotency_key, presence: true
  validates :idempotency_key, length: { maximum: 64 }, uniqueness: { scope: :user_id }
  validates :note, length: { maximum: 5000 }
  validates :product, :target, length: { maximum: 120 }
  validates :label, length: { maximum: 80 }
  validates :humidity_setup, length: { maximum: 120 }
  validates :stage, inclusion: { in: Plant::TC_STAGES }, if: -> { kind == "stage" }
  validates :label, presence: { message: "can't be blank for your own kind of care" }, if: :custom?
  validates :amount, numericality: { greater_than: 0, less_than: 10_000_000 }, allow_nil: true
  validates :amount_unit, inclusion: { in: ->(event) { AMOUNT_UNITS.fetch(event.kind, []) } }, allow_nil: true
  validates :amount_unit, presence: { message: "is needed with an amount" }, if: :amount
  validates :watering_method, inclusion: { in: WATERING_METHODS }, allow_nil: true
  validates :strength, inclusion: { in: STRENGTHS }, allow_nil: true
  validate :note_or_photos
  validate :plant_belongs_to_user

  attr_accessor :photos_expected

  scope :logged, -> { where(kind: LOGGED_KINDS) }
  scope :newest_first, -> { order(occurred_at: :desc, id: :desc) }

  # Returns the event already saved with this key, if any, so a retry creates nothing.
  def self.record_once(user:, plant:, idempotency_key:, **attributes)
    user.care_events.find_by(idempotency_key: idempotency_key) ||
      user.care_events.create(plant: plant, idempotency_key: idempotency_key, **attributes)
  rescue ActiveRecord::RecordNotUnique
    user.care_events.find_by!(idempotency_key: idempotency_key)
  end

  # Earlier products, targets and custom labels a collector typed, latest first, for
  # suggestions (D105): { product: [...], target: [...], label: [...] }.
  def self.suggestions_for(user)
    %i[ product target label ].index_with do |column|
      user.care_events.where.not(column => nil).group(column).order(Arel.sql("MAX(occurred_at) DESC")).limit(30).pluck(column)
    end
  end

  # Latest event of each summary kind for these plants: { plant_id => { "watering" => time } }.
  def self.latest_by_plant(plant_ids, kinds: SUMMARY_KINDS)
    where(plant_id: plant_ids, kind: kinds).group(:plant_id, :kind).maximum(:occurred_at)
      .each_with_object(Hash.new { |hash, key| hash[key] = {} }) { |((plant_id, kind), at), latest| latest[plant_id][kind] = at }
  end

  # Moves and setup changes mirror their history, so they stay as they are (D108). A repot
  # made a setup too, so only its note and details can change, not its date.
  def editable? = !PLACEMENT_KINDS.include?(kind)
  def deletable? = editable? && !(repotting? && plant_setup_id)
  def date_editable? = deletable?

  private
    # Logging care completes the plant's matching reminder that's due or nearly due (D114).
    def complete_open_task
      task = CareTask.completable_by(self) or return
      self.care_task = task
      task.resolve_with!(self)
    end

    def drop_unused_details
      kept = DETAILS.fetch(kind, [])
      (DETAIL_COLUMNS - kept).each { self[it] = TC_CHECK_TICKS.include?(it) ? false : nil }
      TC_CHECK_TICKS.each { self[it] = false if self[it].nil? }
      self.amount_unit = nil if amount.nil?
    end

    def note_or_photos
      errors.add(:note, "can't be blank without a photo") if observation? && note.blank? && !photos_expected && photos.none?
    end

    def plant_belongs_to_user
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
    end
end
