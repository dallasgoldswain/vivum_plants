require "test_helper"

class MaintenanceTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants collection.environments collection.measurements care.logs care.reminders care.shared_maintenance help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    @tank = environments(:tank)
    sign_in_as @user
  end

  test "maintenance is hidden while its flag is off" do
    Flipper.disable("care.shared_maintenance")
    get environment_path(@tank)
    assert_select "#maintenance", 0
    post environment_maintenance_events_path(@tank), params: { environment_event: { kind: "water_change", idempotency_key: "x" } }
    assert_response :not_found
  end

  test "a tank shows its own kinds first" do
    get environment_path(@tank)
    assert_select "#maintenance > section > div.flex button", text: "Water change"
    assert_select "#maintenance > section > div.flex button", text: "Misting check", count: 0
    assert_select "#maintenance details button", text: "Misting check"
  end

  test "one water change is one event linked to the plants present then, not to a plant moved out (EN04)" do
    present = [ plants(:anubias), plants(:monstera_one), plants(:monstera_two) ]
    present.each { it.move_to!(@tank, on: 10.days.ago.to_date) }
    old = plants(:old_fern)
    old.update!(status: "active")
    old.move_to!(@tank, on: 20.days.ago.to_date)
    old.move_to!(environments(:shelf), on: 7.days.ago.to_date)

    assert_no_difference -> { CareEvent.where.not(kind: "movement").count } do
      post environment_maintenance_events_path(@tank), params: { environment_event: { kind: "water_change", amount: "30", amount_unit: "%", idempotency_key: "wc" } }
    end
    event = EnvironmentEvent.sole
    assert_equal present.map(&:id).sort, event.plants.ids.sort

    follow_redirect!
    assert_select "#maintenance .alert h3", /Water change today/
    assert_select "#maintenance .alert a", "Add a reading"

    get plant_path(plants(:anubias))
    assert_select ".vv-timeline li", /Water change in #{@tank.name} · 30%/
    get plant_path(old)
    assert_select ".vv-timeline li", text: /Water change/, count: 0

    delete environment_maintenance_event_path(@tank, event)
    get plant_path(plants(:anubias))
    assert_select ".vv-timeline li", text: /Water change/, count: 0
  end

  test "a water change synced twice creates one event (OF02)" do
    params = { environment_event: { kind: "water_change", idempotency_key: "offline-wc" } }
    assert_difference -> { EnvironmentEvent.count }, 1 do
      2.times { post environment_maintenance_events_path(@tank), params: params, headers: { "Accept" => "application/json" } }
    end
  end

  test "editing the date relinks the plants present then" do
    plants(:anubias).move_to!(@tank, on: 3.days.ago.to_date)
    event = @user.environment_events.create!(environment: @tank, kind: "filter_clean", occurred_at: Time.current, idempotency_key: "f")
    assert_equal [ plants(:anubias) ], event.plants.to_a

    patch environment_maintenance_event_path(@tank, event), params: { environment_event: { occurred_at: 5.days.ago.strftime("%Y-%m-%dT%H:%M"), note: "Rinsed in tank water" } }
    assert_empty event.reload.plants
    assert_equal "Rinsed in tank water", event.note
  end

  test "a weekly water-change reminder shows once on Today, and Done logs one event (D125)" do
    3.times { |i| [ plants(:anubias), plants(:monstera_one), plants(:monstera_two) ][i].move_to!(@tank) }
    post environment_care_schedules_path(@tank), params: { care_schedule: { kind: "water_change", repeats: "repeat", interval: "1", interval_unit: "week", mode: "fixed", starts_on: Date.current.iso8601 } }
    assert_redirected_to environment_path(@tank, anchor: "reminders")
    task = @tank.care_tasks.sole

    get root_path
    assert_select "#today .card h3", "Water change · 1 environment"
    assert_select "#today .card", text: /Water/, count: 1

    post task_completions_path, params: { task_ids: [ task.id ], idempotency_key: "done" }
    assert_equal 1, EnvironmentEvent.count
    assert_equal 0, CareEvent.where.not(kind: "movement").count
    assert_equal Date.current + 7, @tank.care_tasks.open.sole.due_on
  end

  test "logging maintenance completes the environment's due reminder; plant care doesn't" do
    schedule = @user.care_schedules.create!(environment: @tank, kind: "water_change", interval: 7, interval_unit: "day", starts_on: Date.current).tap(&:start!)
    plants(:anubias).move_to!(@tank)
    @user.care_events.create!(plant: plants(:anubias), kind: "watering", occurred_at: Time.current, idempotency_key: "w")
    assert schedule.tasks.sole.open?

    post environment_maintenance_events_path(@tank), params: { environment_event: { kind: "water_change", idempotency_key: "wc" } }
    assert schedule.tasks.order(:id).first.completed?
  end

  test "archiving pauses the environment's reminders and restoring resumes them (D125)" do
    environment = @user.environments.create!(name: "Spare cabinet", kind: "grow_cabinet")
    schedule = @user.care_schedules.create!(environment: environment, kind: "light_check", interval: 1, interval_unit: "month", starts_on: Date.current).tap(&:start!)
    post environment_archive_path(environment)
    assert schedule.reload.paused?
    assert_equal 0, schedule.tasks.open.count
    delete environment_archive_path(environment)
    assert schedule.reload.active?
    assert schedule.open_task
  end

  test "Done with details on an environment task logs a dosing entry" do
    task = @user.care_schedules.create!(environment: @tank, kind: "dosing", interval: 7, interval_unit: "day", starts_on: Date.current).tap(&:start!).open_task
    get new_care_task_completion_path(task)
    assert_response :success
    post care_task_completion_path(task), params: { environment_event: { product: "Liquid carbon", amount: "5", amount_unit: "mL", idempotency_key: "dose" } }
    assert_equal [ "dosing", "Liquid carbon" ], task.reload.environment_event.then { [ it.kind, it.product ] }
  end

  test "someone else's environment maintenance isn't found" do
    other = users(:owner).environment_events.create!(environment: environments(:owner_cabinet), kind: "glass_clean", occurred_at: Time.current, idempotency_key: "o")
    delete environment_maintenance_event_path(environments(:owner_cabinet), other)
    assert_response :not_found
    assert EnvironmentEvent.exists?(other.id)
  end

  test "deleting an environment warns about its maintenance and reminders" do
    environment = @user.environments.create!(name: "Empty tank", kind: "aquarium")
    @user.environment_events.create!(environment: environment, kind: "glass_clean", occurred_at: Time.current, idempotency_key: "g")
    get new_environment_deletion_path(environment)
    assert_match "1 maintenance entry", response.body
    post environment_deletion_path(environment)
    assert_equal 0, EnvironmentEvent.count
  end
end
