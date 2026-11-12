require "test_helper"

class CareScheduleTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @plant = plants(:monstera_one)
  end

  test "a 7-day after-completion schedule done on 10 Nov is next due 17 Nov (AT07)" do
    travel_to Date.new(2026, 11, 10) do
      schedule = make(interval: 7, interval_unit: "day", starts_on: Date.new(2026, 11, 8))
      task = schedule.open_task
      assert_equal Date.new(2026, 11, 8), task.due_on
      task.complete!(idempotency_key: "k")
      assert_equal Date.new(2026, 11, 17), schedule.reload.open_task.due_on
    end
  end

  test "a fixed weekly schedule completed late keeps its weekday (AT07)" do
    monday = Date.new(2026, 11, 2)
    travel_to monday + 2 do
      schedule = make(interval: 1, interval_unit: "week", mode: "fixed", starts_on: monday)
      schedule.open_task.complete!(idempotency_key: "k")
      assert_equal monday + 7, schedule.reload.open_task.due_on
      assert schedule.open_task.due_on.monday?
    end
  end

  test "a monthly schedule from 31 Jan clamps to the end of February, then returns to the 31st" do
    schedule = @user.care_schedules.new(plant: @plant, kind: "feeding", interval: 1, interval_unit: "month", mode: "fixed", starts_on: Date.new(2027, 1, 31))
    assert_equal [ Date.new(2027, 1, 31), Date.new(2027, 2, 28), Date.new(2027, 3, 31), Date.new(2027, 4, 30) ], schedule.preview(4)
    assert_equal Date.new(2028, 2, 29), schedule.next_due_after(due_on: Date.new(2028, 1, 31), resolved_on: Date.new(2028, 1, 31))
  end

  test "skipping logs no care and makes the next task; an overdue schedule shows one task (CA03)" do
    travel_to Date.new(2026, 11, 20) do
      schedule = make(interval: 2, interval_unit: "day", starts_on: Date.new(2026, 11, 1))
      assert_equal 1, schedule.tasks.open.count
      assert_equal 19, schedule.open_task.days_overdue

      schedule.open_task.skip!
      assert_equal 0, CareEvent.count
      assert_equal [ "skipped", "open" ], schedule.tasks.order(:id).pluck(:state)
      assert_equal Date.new(2026, 11, 22), schedule.reload.open_task.due_on
    end
  end

  test "completing a task logs one linked event, and a retry logs none (CA01)" do
    task = make.open_task
    event = task.complete!(idempotency_key: "done-1")
    again = task.reload.complete!(idempotency_key: "done-1")
    assert_equal event, again
    assert_equal [ "watering" ], @plant.care_events.pluck(:kind)
    assert_equal task, event.care_task
    assert task.reload.completed?
  end

  test "logging care completes a task due within 2 days, and Undo reopens it (D114)" do
    schedule = make(interval: 7, interval_unit: "day", starts_on: Date.current + 1)
    task = schedule.open_task
    event = log("watering")
    assert task.reload.completed?
    assert_equal Date.current + 7, schedule.reload.open_task.due_on

    event.destroy!
    assert task.reload.open?
    assert_equal [ task ], schedule.tasks.open.to_a
  end

  test "care of another kind, or a task further ahead, isn't completed" do
    far = make(starts_on: Date.current + 5).open_task
    log("watering")
    assert far.reload.open?

    feeding = make(kind: "feeding").open_task
    log("pruning")
    assert feeding.reload.open?
  end

  test "custom reminders complete only on the same label" do
    task = make(kind: "custom", label: "Flush with RO water").open_task
    log("custom", label: "Wipe leaves")
    assert task.reload.open?
    log("custom", label: "flush with ro water")
    assert task.reload.completed?
  end

  test "snoozing hides a task until the chosen day and keeps its due date (D116)" do
    task = make.open_task
    task.snooze!(Date.current + 3)
    assert_not_includes @user.care_tasks.visible_on(Date.current), task
    assert_includes @user.care_tasks.visible_on(Date.current + 3), task
    assert_equal Date.current, task.due_on
    assert_not task.update(snoozed_until: Date.current)
  end

  test "editing a schedule moves its open task unless that date was set by hand (CA05, D118)" do
    schedule = make(interval: 7, interval_unit: "day", starts_on: Date.current + 3)
    schedule.update!(starts_on: Date.current + 1)
    schedule.reschedule_open_task!
    assert_equal Date.current + 1, schedule.open_task.due_on

    schedule.open_task.move_to!(Date.current + 10)
    schedule.update!(starts_on: Date.current + 2)
    schedule.reschedule_open_task!
    assert_equal Date.current + 10, schedule.open_task.reload.due_on
  end

  test "an inactive plant's reminders pause, and restoring creates no past tasks (PL03, D119)" do
    schedule = make(interval: 1, interval_unit: "week", mode: "fixed", starts_on: Date.current - 21)
    @plant.change_status!("sold")
    assert schedule.reload.paused?
    assert_equal 0, schedule.tasks.open.count

    travel 10.days do
      @plant.change_status!("active")
      assert schedule.reload.active?
      assert_operator schedule.open_task.due_on, :>=, Date.current
    end
  end

  test "a one-off is done once; ending a schedule keeps its history" do
    schedule = make(interval: nil)
    schedule.open_task.complete!(idempotency_key: "once")
    assert_nil schedule.reload.open_task

    weekly = make(kind: "feeding", interval: 1, interval_unit: "week")
    weekly.open_task.skip!
    weekly.end!
    assert_equal %w[ skipped cancelled ], weekly.tasks.order(:id).pluck(:state)
  end

  private
    def make(kind: "watering", interval: 7, interval_unit: "day", mode: "after_completion", starts_on: Date.current, label: nil)
      @user.care_schedules.create!(plant: @plant, kind: kind, label: label, interval: interval, interval_unit: interval_unit, mode: mode, starts_on: starts_on).tap(&:start!)
    end

    def log(kind, **details)
      @user.care_events.create!(plant: @plant, kind: kind, occurred_at: Time.current, idempotency_key: SecureRandom.uuid, **details)
    end
end
