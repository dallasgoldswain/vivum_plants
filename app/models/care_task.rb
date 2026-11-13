# One occurrence of a reminder (CA03, D118). Open tasks are upcoming, due or overdue by their
# date; done and skipped tasks keep the date they were due. Snoozing hides a task from Today
# until a day without moving its due date (D116).
class CareTask < ApplicationRecord
  STATES = %w[ open completed skipped cancelled ].freeze
  # Logging care completes a task due this many days ahead (D114).
  EARLY_DAYS = 2

  belongs_to :user
  belongs_to :plant, optional: true
  belongs_to :environment, optional: true
  belongs_to :care_schedule
  has_one :care_event, dependent: :nullify
  has_one :environment_event, dependent: :nullify

  enum :state, STATES.index_by(&:itself), validate: true, default: "open"

  validates :due_on, presence: true
  validate :snooze_ahead, if: :snoozed_until_changed?

  scope :resolved, -> { where(state: %w[ completed skipped ]) }
  scope :visible_on, ->(date) { open.where("snoozed_until IS NULL OR snoozed_until <= ?", date) }
  scope :snoozed_on, ->(date) { open.where("snoozed_until > ?", date) }

  delegate :kind, :label, :note, to: :care_schedule

  def subject = plant || environment
  def logged_event = care_event || environment_event

  def overdue?(today = Date.current) = open? && due_on < today
  def due_today?(today = Date.current) = open? && due_on == today
  def days_overdue(today = Date.current) = (today - due_on).to_i

  # The plant's open task this care can complete: overdue, due today or due within
  # EARLY_DAYS of when the care happened (D114).
  def self.completable_by(event)
    date = event.occurred_at.to_date
    event.plant.care_tasks.open.where(due_on: ..(date + EARLY_DAYS)).includes(:care_schedule).order(:due_on, :id)
      .find { it.care_schedule.matches?(event.kind, event.label) }
  end

  # Done (D113): logs the matching care now, linked to this task. A retry with the same key,
  # or a task already done, logs nothing more.
  def complete!(idempotency_key:, occurred_at: Time.current, **details)
    with_lock do
      return logged_event if completed?
      return unless open?

      events = environment ? user.environment_events : user.care_events
      attributes = { kind: kind, label: label, occurred_at: occurred_at, idempotency_key: idempotency_key, care_task: self, **details.except(:label) }
      event = events.find_by(idempotency_key: idempotency_key) || events.create!(environment ? { environment: environment, **attributes } : { plant: plant, **attributes })
      resolve_with!(event) unless completed?
      event
    end
  end

  # Marks this task done by a care event and makes the next one.
  def resolve_with!(event)
    event.update_columns(care_task_id: id) unless event.care_task_id == id
    resolve!("completed", on: event.occurred_at.to_date)
  end

  # Skip logs no care and makes the next task (CA03).
  def skip!(on: Date.current)
    with_lock { resolve!("skipped", on: on) if open? }
  end

  def snooze!(until_date)
    update!(snoozed_until: until_date)
  end

  def move_to!(date)
    update!(due_on: date, due_on_changed_by_hand: true, snoozed_until: nil)
  end

  def cancel!
    update!(state: "cancelled", resolved_at: Time.current)
  end

  # Undo of the care that completed it (D114): the task opens again and the one made after it
  # goes, unless that one has been dealt with since.
  def reopen!
    transaction do
      later = care_schedule.tasks.open.first
      later.destroy! if later && later != self && !later.due_on_changed_by_hand? && later.snoozed_until.nil?
      update!(state: "open", resolved_at: nil, resolved_on: nil) unless care_schedule.tasks.open.exists?
    end
  end

  private
    def resolve!(state, on:)
      transaction do
        update!(state: state, resolved_at: Time.current, resolved_on: on, snoozed_until: nil)
        if care_schedule.active? && (due = care_schedule.next_due_after(due_on: due_on, resolved_on: on))
          care_schedule.tasks.create!(user: user, plant: plant, environment: environment, due_on: due)
        end
      end
    end

    def snooze_ahead
      errors.add(:snoozed_until, "must be after today") if snoozed_until && snoozed_until <= Date.current
    end
end
