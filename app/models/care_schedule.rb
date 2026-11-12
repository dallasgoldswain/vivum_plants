# A reminder for one plant: what to do, how often, and how the next date is counted (CA02,
# D112, D117). It has at most one open task; the next one is made when that task is done or
# skipped, so an overdue reminder never stacks up (CA03, D118).
class CareSchedule < ApplicationRecord
  KINDS = CareEvent::LOGGED_KINDS
  INTERVAL_UNITS = %w[ day week month ].freeze
  # after_completion counts from when it was done; fixed keeps to the calendar from the start.
  MODES = %w[ after_completion fixed ].freeze
  STATUSES = %w[ active paused ended ].freeze

  belongs_to :user
  belongs_to :plant
  has_many :tasks, class_name: "CareTask", dependent: :destroy
  has_one :open_task, -> { open }, class_name: "CareTask"

  enum :kind, KINDS.index_by(&:itself), validate: true
  enum :mode, MODES.index_by(&:itself), validate: true
  enum :status, STATUSES.index_by(&:itself), validate: true, default: "active"

  normalizes :label, :note, with: ->(value) { value.squish.presence }

  before_validation { self.interval_unit = nil if interval.nil? }

  validates :starts_on, presence: true
  validates :label, presence: { message: "can't be blank for your own kind of care" }, if: :custom?
  validates :label, length: { maximum: 80 }
  validates :note, length: { maximum: 200 }
  validates :interval, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 }, allow_nil: true
  validates :interval_unit, inclusion: { in: INTERVAL_UNITS }, if: :interval
  validate :plant_belongs_to_user

  scope :running, -> { where(status: "active") }

  def repeating? = interval.present?
  def once? = !repeating?

  # Same kind of care (and, for your own kinds, the same label): used for the duplicate
  # check (D120) and for logged care completing a task (D114).
  def matches?(kind, label = nil) = self.kind == kind && (!custom? || self.label.to_s.casecmp?(label.to_s))

  def same_kind_for_plant
    plant.care_schedules.running.where(kind: kind).where.not(id: id).select { it.matches?(kind, label) }
  end

  # The date after a task due on `due_on` was resolved on `resolved_on`, or nil when a one-off
  # is finished. After-completion counts from the day it was done; fixed keeps to the
  # calendar from the start date, so a late weekly task keeps its weekday (AT07).
  def next_due_after(due_on:, resolved_on:)
    return if once?
    return advance(resolved_on, 1) if after_completion?

    occurrence_after([ due_on, resolved_on ].max)
  end

  # The first date on or after `date`: fixed schedules keep to their calendar, others
  # simply start then. Used when a reminder starts or resumes (D119).
  def due_from(date)
    return [ starts_on, date ].max if once? || after_completion?

    starts_on >= date ? starts_on : occurrence_after(date - 1)
  end

  # The first few dates from the start, assuming each is done on the day (CA02). The
  # schedule form shows the same in the browser (schedule_preview_controller.js).
  def preview(count = 5)
    return [ starts_on ] if once?

    (1...count).reduce([ starts_on ]) { |dates, _| dates << next_due_after(due_on: dates.last, resolved_on: dates.last) }
  end

  # Creates the first task, due on the start date, even one in the past.
  def start! = open_task_from!(starts_on)

  # Creates the open task if there isn't one: when a reminder starts or resumes.
  def open_task_from!(date)
    tasks.open.first || tasks.create!(user: user, plant: plant, due_on: due_from(date)).tap { association(:open_task).reset }
  end

  # A change to the schedule moves its open task, unless that date was set by hand (D118).
  def reschedule_open_task!
    task = tasks.open.first or return
    return if task.due_on_changed_by_hand?

    last = tasks.resolved.order(:resolved_on, :id).last
    due = last ? next_due_after(due_on: last.due_on, resolved_on: last.resolved_on) : due_from(starts_on)
    due ? task.update!(due_on: due) : task.update!(state: "cancelled", resolved_at: Time.current)
  end

  def pause!(by_status: false)
    transaction do
      update!(status: "paused", paused_by_status: by_status)
      tasks.open.first&.cancel!
    end
  end

  def resume!(from: Date.current)
    transaction do
      update!(status: "active", paused_by_status: false)
      open_task_from!(from)
    end
  end

  # Ending keeps completed and skipped history (D120).
  def end!
    transaction do
      update!(status: "ended")
      tasks.open.first&.cancel!
    end
  end

  private
    def advance(date, steps)
      case interval_unit
      when "day" then date + (interval * steps)
      when "week" then date + (interval * 7 * steps)
      when "month" then date >> (interval * steps)
      end
    end

    # The first calendar occurrence after `date`, counted from the start date so months clamp
    # without drifting (31 Jan → 28 Feb → 31 Mar).
    def occurrence_after(date)
      return starts_on if starts_on > date

      steps =
        case interval_unit
        when "day" then (date - starts_on).to_i / interval
        when "week" then (date - starts_on).to_i / (interval * 7)
        when "month" then ((date.year * 12 + date.month) - (starts_on.year * 12 + starts_on.month)) / interval
        end
      steps += 1 while advance(starts_on, steps) <= date
      advance(starts_on, steps)
    end

    def plant_belongs_to_user
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
    end
end
