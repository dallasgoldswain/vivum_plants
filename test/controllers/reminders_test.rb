require "test_helper"

class RemindersTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants collection.search collection.environments care.logs care.reminders help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    @plant = plants(:monstera_one)
    sign_in_as @user
  end

  test "with reminders off, home stays as it was and reminder pages are hidden" do
    Flipper.disable("care.reminders")
    get root_path
    assert_select "h1", "Welcome to VIVUM Plants"
    assert_select "#today", 0
    get new_plant_care_schedule_path(@plant)
    assert_response :not_found
  end

  test "setting a reminder shows it on the plant and on Today (CA02, CA04, D111)" do
    post plant_care_schedules_path(@plant), params: { care_schedule: { kind: "watering", repeats: "repeat", interval: "7", interval_unit: "day", mode: "after_completion", starts_on: Date.current.iso8601 } }
    assert_redirected_to plant_path(@plant, anchor: "reminders")
    follow_redirect!
    assert_select "#reminders", /Every 7 days after it's done/
    assert_select "#reminders .badge-secondary", "Due today"

    get root_path
    assert_select "h1", "Today"
    assert_select "nav a", text: "Today"
    assert_select "#today .card h3", "Water · 1 plant"
  end

  test "a second reminder of the same kind shows the existing one first (CA05, D120)" do
    schedule(kind: "watering")
    params = { care_schedule: { kind: "watering", repeats: "repeat", interval: "3", interval_unit: "day", mode: "after_completion", starts_on: Date.current.iso8601 } }
    post plant_care_schedules_path(@plant), params: params
    assert_select "h1", /already has this reminder/
    assert_equal 1, @plant.care_schedules.count

    post plant_care_schedules_path(@plant), params: params.merge(duplicate: "replace")
    assert_equal %w[ ended active ], @plant.care_schedules.order(:id).pluck(:status)
  end

  test "Done on a group logs one event per plant, and a retry logs no more (D113, D115)" do
    tasks = [ @plant, plants(:monstera_two), plants(:anubias) ].map { schedule(plant: it).open_task }
    params = { task_ids: tasks.map(&:id), idempotency_key: "group-1" }
    assert_difference -> { CareEvent.watering.count }, 3 do
      2.times { post task_completions_path, params: params, headers: { "Accept" => "application/json" } }
    end
    assert tasks.all? { it.reload.completed? }
    assert_equal tasks.map(&:id).sort, CareEvent.watering.pluck(:care_task_id).sort
  end

  test "Done with details logs the details on the linked event" do
    task = schedule(kind: "feeding").open_task
    get new_care_task_completion_path(task)
    assert_response :success
    post care_task_completion_path(task), params: { care_event: { product: "Seaweed feed", amount: "2", amount_unit: "mL/L", idempotency_key: "d" } }
    event = task.reload.care_event
    assert_equal [ "feeding", "Seaweed feed" ], [ event.kind, event.product ]
  end

  test "skip logs no care; snooze hides the task until the day (CA03, D116)" do
    task = schedule.open_task
    post care_task_snooze_path(task), params: { until: "3" }
    get root_path
    assert_select "#today .card h3", count: 0
    assert_match "Snoozed · 1", response.body

    post care_task_skip_path(task), headers: { "Accept" => "application/json" }
    assert_response :created
    assert task.reload.skipped?
    assert_equal 0, CareEvent.count
  end

  test "snoozing to today or earlier is refused" do
    task = schedule.open_task
    post care_task_snooze_path(task), params: { until_date: Date.current.iso8601 }, headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity
  end

  test "tapping Water completes the watering reminder due tomorrow and says so (D114)" do
    task = schedule(starts_on: Date.current + 1).open_task
    post plant_care_events_path(@plant), params: { care_event: { kind: "watering", idempotency_key: "tap" } }
    follow_redirect!
    assert task.reload.completed?
    assert_select "#care .alert", /Also completed its water reminder/
  end

  test "changing a task's date, pausing, resuming and ending (D118–D120)" do
    s = schedule
    patch care_task_path(s.open_task), params: { care_task: { due_on: (Date.current + 4).iso8601 } }
    assert s.open_task.reload.due_on_changed_by_hand?

    post plant_care_schedule_pause_path(@plant, s)
    assert s.reload.paused?
    delete plant_care_schedule_pause_path(@plant, s)
    assert s.reload.active?
    delete plant_care_schedule_path(@plant, s)
    assert s.reload.ended?
    assert_nil s.open_task
  end

  test "reminders for the plants in an environment leave out plants that already have one (D112)" do
    [ @plant, plants(:monstera_two) ].each { it.move_to!(environments(:shelf)) }
    schedule(plant: @plant)
    get new_care_schedule_path(environment_id: environments(:shelf).id)
    assert_select "input[name='plant_ids[]'][checked]", 2

    post care_schedules_path, params: { plant_ids: [ @plant.id, plants(:monstera_two).id ], environment_id: environments(:shelf).id, duplicate: "leave_out",
                                        care_schedule: { kind: "watering", repeats: "repeat", interval: "1", interval_unit: "week", mode: "fixed", starts_on: Date.current.iso8601 } }
    assert_equal "Reminder set for 1 plant (1 already had one).", flash[:notice]
    assert_equal 1, plants(:monstera_two).care_schedules.count
  end

  test "someone else's tasks and schedules aren't found" do
    other = users(:owner).care_schedules.create!(plant: plants(:owner_philodendron), kind: "watering", starts_on: Date.current).tap(&:start!)
    post care_task_skip_path(other.open_task)
    assert_response :not_found
    post task_completions_path, params: { task_ids: [ other.open_task.id ] }
    assert other.open_task.reload.open?
    delete plant_care_schedule_path(plants(:owner_philodendron), other)
    assert_response :not_found
  end

  test "the timezone decides today, and comes from the browser the first time (D117)" do
    @user.update!(time_zone: nil)
    cookies[:time_zone] = "Pacific/Auckland"
    get root_path
    assert_equal "Pacific/Auckland", @user.reload.time_zone

    patch settings_time_zone_path, params: { time_zone: "Nowhere/Land" }
    assert_equal "Pacific/Auckland", @user.reload.time_zone
    patch settings_time_zone_path, params: { time_zone: "Africa/Johannesburg" }
    assert_equal "Africa/Johannesburg", @user.reload.time_zone
  end

  private
    def schedule(plant: @plant, kind: "watering", starts_on: Date.current)
      @user.care_schedules.create!(plant: plant, kind: kind, interval: 7, interval_unit: "day", starts_on: starts_on).tap(&:start!)
    end
end
