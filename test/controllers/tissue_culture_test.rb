require "test_helper"

class TissueCultureControllerTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants collection.environments collection.acquisition collection.tissue_culture care.logs care.reminders help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    sign_in_as @user
  end

  test "TC pages are hidden while the flag is off" do
    Flipper.disable("collection.tissue_culture")
    get new_acquisition_path
    assert_response :not_found
    get plants_path
    assert_select "a", text: "Record a TC purchase", count: 0
  end

  test "recording a purchase makes a record per plantlet and shows arrival vs remaining (TC01)" do
    assert_difference -> { @user.plants.count }, 5 do
      post acquisitions_path, params: { tissue_culture_purchase: { name: "Monstera TC", quantity: "5", stage: "sealed", growing_context: "indoor", source: "Lab Co", container_condition: "intact", acquired_on: Date.current.iso8601 } }
    end
    group = @user.acquisitions.purchase_groups.sole
    assert_redirected_to acquisition_path(group)
    follow_redirect!
    assert_select "h1", "Monstera TC"
    assert_match "5 of 5 remain", response.body
    assert_select "input[name='plant_ids[]'][checked]", 5
  end

  test "a purchase with a missing name or too many plantlets is refused" do
    post acquisitions_path, params: { tissue_culture_purchase: { name: "", quantity: "60" } }
    assert_response :unprocessable_entity
    assert_equal 0, @user.acquisitions.purchase_groups.count
  end

  test "changing stage to deflasked in a terrarium offers suggestions, and only ticked ones are added (TC04)" do
    plant = purchase(1, context: "terrarium").plants.sole
    post plant_stage_changes_path(plant), params: { stage: "deflasked", on: Date.current.iso8601 }
    assert_redirected_to new_tc_suggestion_path(plant_ids: [ plant.id ], stage: "deflasked")
    follow_redirect!
    assert_select "label", text: /Check readiness for repotting/

    suggestions = TissueCulture::Suggestions.for("deflasked", "terrarium")
    readiness = suggestions.index { it.label == "Check readiness for repotting" }
    rows = suggestions.each_with_index.to_h { |s, i| [ i.to_s, { add: (i == readiness ? "1" : "0"), kind: s.kind, label: s.label, interval: s.interval.to_s, interval_unit: s.interval_unit, starts_on: (Date.current + s.starts_in_days).iso8601 } ] }
    post tc_suggestions_path, params: { plant_ids: [ plant.id ], suggestions: rows }
    assert_equal [ "Check readiness for repotting" ], plant.care_schedules.pluck(:label)
    assert_equal "tc_stage", plant.care_schedules.sole.origin
    assert_equal "deflasked", plant.reload.tc_stage
  end

  test "a stage change synced twice records one stage entry (D134)" do
    plant = purchase(1).plants.sole
    2.times { post plant_stage_changes_path(plant), params: { stage: "deflasked", idempotency_key: "s1" }, headers: { "Accept" => "application/json" } }
    assert_equal 1, plant.care_events.where(kind: "stage", stage: "deflasked").count
    assert_equal new_tc_suggestion_path(plant_ids: [ plant.id ], stage: "deflasked"), response.parsed_body["location"]
  end

  test "established lists open TC reminders with keep, end or replace and removes none silently (TC05)" do
    plant = purchase(1).plants.sole
    inspect = tc_schedule(plant, "inspection")
    ventilate = tc_schedule(plant, "custom", "Ventilation review")
    post plant_stage_changes_path(plant), params: { stage: "established" }
    assert_redirected_to new_plant_tc_review_path(plant)

    post plant_tc_review_path(plant), params: { choices: { inspect.id => "keep" } }
    assert_redirected_to new_plant_tc_review_path(plant)
    assert inspect.reload.active? && ventilate.reload.active?

    post plant_tc_review_path(plant), params: { choices: { inspect.id => "keep", ventilate.id => "replace" } }
    assert_redirected_to new_plant_care_schedule_path(plant)
    assert inspect.reload.active?
    assert_nil inspect.origin
    assert ventilate.reload.ended?
  end

  test "group actions change stage, log a check and mark ticked plantlets lost (D130)" do
    group = purchase(4)
    plants = group.plants.order(:number).to_a
    post acquisition_group_action_path(group), params: { group_action: "check", plant_ids: plants.map(&:id), check: { new_roots: "1", note: "Roots in the plugs" } }
    assert_equal 4, CareEvent.where(kind: "inspection", new_roots: true).count

    post acquisition_group_action_path(group), params: { group_action: "lost", plant_ids: [ plants.first.id ] }
    assert plants.first.reload.lost?
    assert_match "3 of 4 remain", flash[:notice]

    Flipper.disable("care.reminders")
    post acquisition_group_action_path(group), params: { group_action: "stage", stage: "acclimatising", plant_ids: plants.drop(1).map(&:id) }
    assert_equal %w[ sealed acclimatising acclimatising acclimatising ], plants.map { it.reload.tc_stage }
  end

  test "a TC check on the plant page saves its ticks and doesn't change the stage" do
    plant = purchase(1, stage: "deflasked").plants.sole
    get plant_path(plant)
    assert_select "#tissue-culture", /Deflasked since/
    assert_select "#care-inspection input[name='care_event[suspected_contamination]']"

    post plant_care_events_path(plant), params: { care_event: { kind: "inspection", damage: "1", humidity_setup: "Dome vented", idempotency_key: "chk" } }
    event = plant.care_events.find_by!(idempotency_key: "chk")
    assert event.damage?
    assert_equal "deflasked", plant.reload.tc_stage
    follow_redirect!
    assert_select ".vv-timeline li", /Damage · Humidity: Dome vented/
  end

  test "splitting a planting of 5 into 2 and 3 copies only the ticked reminders (PL06)" do
    plant = plants(:anubias)
    plant.update!(quantity: 5)
    water = @user.care_schedules.create!(plant: plant, kind: "watering", interval: 7, interval_unit: "day", starts_on: Date.current).tap(&:start!)
    @user.care_schedules.create!(plant: plant, kind: "feeding", interval: 14, interval_unit: "day", starts_on: Date.current).start!

    get new_plant_split_path(plant)
    assert_response :success
    post plant_split_path(plant), params: { quantities: [ "3", "" ], copy_schedule_ids: [ water.id ] }
    part = Plant.find_by!(split_from: plant)
    assert_equal [ 2, 3 ], [ plant.reload.quantity, part.quantity ]
    assert_equal [ "watering" ], part.care_schedules.pluck(:kind)

    post plant_split_path(plant), params: { quantities: [ "2" ] }
    assert_match "Keep at least 1", flash[:alert]
  end

  test "an empty purchase can be deleted; one with plantlets can't" do
    group = purchase(1)
    delete acquisition_path(group)
    assert Acquisition.exists?(group.id)
    group.plants.sole.destroy!
    delete acquisition_path(group)
    assert_not Acquisition.exists?(group.id)
  end

  test "someone else's purchase isn't found" do
    other = TissueCulture::Purchase.new(user: users(:owner), name: "Theirs", quantity: 1).tap(&:save).acquisition
    get acquisition_path(other)
    assert_response :not_found
    post acquisition_group_action_path(other), params: { group_action: "lost", plant_ids: other.plants.ids }
    assert_response :not_found
    assert other.plants.sole.reload.active?
  end

  private
    def purchase(quantity, stage: "sealed", context: "indoor")
      TissueCulture::Purchase.new(user: @user, name: "Monstera TC", quantity: quantity, stage: stage, growing_context: context).tap { assert it.save }.acquisition
    end

    def tc_schedule(plant, kind, label = nil)
      @user.care_schedules.create!(plant: plant, kind: kind, label: label, interval: 7, interval_unit: "day", starts_on: Date.current, origin: "tc_stage").tap(&:start!)
    end
end
