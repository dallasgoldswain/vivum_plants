require "test_helper"

class CareTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants collection.search collection.environments collection.media substrate.ingredients substrate.recipes care.logs help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    @plant = plants(:monstera_one)
    sign_in_as @user
  end

  test "care entry is hidden while its flag is off; observations still work" do
    Flipper.disable("care.logs")
    get plant_path(@plant)
    assert_select "#care", 0
    assert_select "#observe"

    post plant_care_events_path(@plant), params: { care_event: { kind: "watering", idempotency_key: "w" } }
    assert_response :not_found
    get new_care_log_path
    assert_response :not_found
  end

  test "tapping Water saves one watering without a form, with Undo and Add details (D103)" do
    assert_difference -> { @plant.care_events.watering.count }, 1 do
      post plant_care_events_path(@plant), params: { care_event: { kind: "watering", idempotency_key: "tap-1" } }
    end
    follow_redirect!
    assert_select "#care .alert h3", /Watered today/
    assert_select "#care a", "Add details"
    assert_select "#care button", "Undo"
    assert_select "#care header p", "Watered today"

    event = @plant.care_events.watering.sole
    delete plant_care_event_path(@plant, event)
    assert_equal 0, @plant.care_events.count
  end

  test "a care entry synced twice creates one event (OF02)" do
    params = { care_event: { kind: "feeding", product: "Seaweed feed", amount: "2", amount_unit: "mL/L", idempotency_key: "offline-feed" } }
    assert_difference -> { CareEvent.count }, 1 do
      2.times { post plant_care_events_path(@plant), params: params, headers: { "Accept" => "application/json" } }
    end
    assert_response :created
  end

  test "a refused entry answers with its errors for the offline queue" do
    post plant_care_events_path(@plant), params: { care_event: { kind: "custom", idempotency_key: "c" } }, headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity
    assert_match "blank", response.parsed_body["errors"].join
  end

  test "a repot into a new pot with Aroid mix v1 is one timeline entry and the current setup (D106)" do
    post plant_care_events_path(@plant), params: {
      care_event: { kind: "repotting", idempotency_key: "repot", occurred_at: Time.current.strftime("%Y-%m-%dT%H:%M") },
      setup: { container: "Clay pot", size: "14", size_unit: "cm", recipe_version_id: recipe_versions(:aroid_v1).id }
    }
    follow_redirect!
    assert_select ".vv-timeline li", text: /Repotted.*Into Clay pot · 14 cm · Aroid mix v1/m, count: 1
    assert_equal "Clay pot", @plant.reload.current_setup.container
    assert_equal 0, @plant.care_events.setup.count
  end

  test "editing a care entry changes its details and date; a repot keeps its date (D108)" do
    event = @user.care_events.create!(plant: @plant, kind: "watering", occurred_at: Time.current, idempotency_key: "e")
    get edit_plant_care_event_path(@plant, event)
    assert_response :success
    patch plant_care_event_path(@plant, event), params: { care_event: { amount: "300", amount_unit: "mL", watering_method: "bottom", occurred_at: 1.day.ago.strftime("%Y-%m-%dT%H:%M") } }
    assert_equal [ 300, "bottom", 1.day.ago.to_date ], event.reload.then { [ it.amount, it.watering_method, it.occurred_at.to_date ] }

    repot = @user.care_events.new(plant: @plant, kind: "repotting", occurred_at: 3.days.ago, idempotency_key: "r")
    @plant.repot!(repot, { container: "Glass jar" })
    patch plant_care_event_path(@plant, repot), params: { care_event: { note: "Roots looked healthy", occurred_at: Time.current.strftime("%Y-%m-%dT%H:%M") } }
    assert_equal [ "Roots looked healthy", 3.days.ago.to_date ], repot.reload.then { [ it.note, it.occurred_at.to_date ] }
    delete plant_care_event_path(@plant, repot)
    assert CareEvent.exists?(repot.id)
  end

  test "moves can't be edited or deleted, and someone else's entries aren't found" do
    @plant.move_to!(environments(:shelf))
    movement = @plant.care_events.movement.sole
    get edit_plant_care_event_path(@plant, movement)
    assert_response :not_found

    owners = plants(:owner_philodendron)
    other = users(:owner).care_events.create!(plant: owners, kind: "pruning", occurred_at: Time.current, idempotency_key: "o")
    patch plant_care_event_path(owners, other), params: { care_event: { note: "Mine" } }
    assert_response :not_found
  end

  test "watering the plants in an environment creates one event each, and a retry no more (D107)" do
    plants = [ @plant, plants(:monstera_two), plants(:anubias) ]
    plants.each { it.move_to!(environments(:shelf)) }
    get new_care_log_path(environment_id: environments(:shelf).id)
    assert_select "input[name='plant_ids[]'][checked]", 3

    params = { plant_ids: plants.map(&:id), environment_id: environments(:shelf).id, care_event: { kind: "watering", amount: "250", amount_unit: "mL", idempotency_key: "shelf-1" } }
    assert_difference -> { CareEvent.watering.count }, 3 do
      2.times { post care_logs_path, params: params, headers: { "Accept" => "application/json" } }
    end
    assert_equal [ 250 ] * 3, CareEvent.watering.pluck(:amount)
  end

  test "several-plant logging refuses repots and someone else's plants" do
    post care_logs_path, params: { plant_ids: [ @plant.id ], care_event: { kind: "repotting", idempotency_key: "x" } }, headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity

    post care_logs_path, params: { plant_ids: [ plants(:owner_philodendron).id ], care_event: { kind: "watering", idempotency_key: "y" } }, headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity
    assert_equal 0, CareEvent.count
  end

  test "the collection shows last watering and filters plants not watered in 7+ days (D109)" do
    @user.care_events.create!(plant: @plant, kind: "watering", occurred_at: 8.days.ago, idempotency_key: "a")
    @user.care_events.create!(plant: plants(:monstera_two), kind: "watering", occurred_at: 2.days.ago, idempotency_key: "b")

    get plants_path(view: "list")
    assert_match "Watered 8 days ago", response.body
    assert_match "Not watered yet", response.body

    get plants_path(view: "list", unwatered: 7)
    assert_select "a.vv-plant-row[href=?]", plant_path(@plant)
    assert_select "a.vv-plant-row[href=?]", plant_path(plants(:monstera_two)), 0
  end

  test "the timeline filters by kind" do
    @user.care_events.create!(plant: @plant, kind: "watering", occurred_at: 1.day.ago, idempotency_key: "a")
    @user.care_events.create!(plant: @plant, kind: "pruning", occurred_at: Time.current, idempotency_key: "b")
    get plant_path(@plant, kind: "pruning")
    assert_select ".vv-timeline li", 1
    assert_select ".vv-timeline li", /Pruned/
  end
end
