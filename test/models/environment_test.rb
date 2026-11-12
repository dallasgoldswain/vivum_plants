require "test_helper"

# Environments, moves, setups and readings (B11, EN01–EN03, PL05, D88–D95).
class EnvironmentTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @shelf, @tank = environments(:shelf), environments(:tank)
    @plant = plants(:monstera_one)
  end

  test "a tank saves with only a name and type" do
    assert @user.environments.create(name: "Nano", kind: "aquarium").persisted?
    assert_not @user.environments.new(name: "Nano").valid?
    assert_not @user.environments.new(kind: "aquarium").valid?
  end

  test "a moved plant is only in its new environment, and both keep it in their history" do
    @plant.move_to!(@shelf, on: 10.days.ago.to_date)
    @plant.move_to!(@tank, on: 2.days.ago.to_date)

    assert_equal [ @plant ], @tank.current_plants.to_a
    assert_empty @shelf.current_plants
    assert_equal [ @shelf, @tank ], @plant.environment_assignments.map(&:environment)
    assert_equal 2.days.ago.to_date, @plant.environment_assignments.first.ended_on
    assert_equal [ @shelf, @tank ], @plant.care_events.movement.order(:occurred_at).map(&:environment)
    assert_equal @shelf, @plant.care_events.movement.order(:occurred_at).last.from_environment
  end

  test "moves can't overlap, go to the future or repeat the current environment" do
    @plant.move_to!(@shelf, on: 3.days.ago.to_date)

    assert_raises(Plant::Placement::MoveRefused) { @plant.move_to!(@tank, on: 4.days.ago.to_date) }
    assert_raises(Plant::Placement::MoveRefused) { @plant.move_to!(@tank, on: Date.tomorrow) }
    assert_raises(Plant::Placement::MoveRefused) { @plant.move_to!(@shelf) }
    assert_equal @shelf, @plant.reload.current_environment
  end

  test "taking a plant out leaves it in no environment" do
    @plant.move_to!(@shelf, on: 3.days.ago.to_date)
    @plant.move_to!(nil)

    assert_nil @plant.reload.current_environment
    assert_raises(Plant::Placement::MoveRefused) { @plant.move_to!(nil) }
  end

  test "an indoor plant moved into an aquarium is offered aquatic and keeps indoor if declined" do
    @plant.move_to!(@tank)
    assert @plant.current_assignment.context_offer?

    @plant.answer_context_offer!(accept: false)
    assert_equal "indoor", @plant.reload.growing_context
    assert_not @plant.current_assignment.context_offer?

    other = plants(:monstera_two)
    other.move_to!(@tank)
    other.answer_context_offer!(accept: true)
    assert_equal "aquatic", other.reload.growing_context
  end

  test "no offer when the context already matches or the type suggests none" do
    plants(:anubias).move_to!(@tank)
    assert_not plants(:anubias).current_assignment.context_offer?

    box = @user.environments.create!(name: "Tub", kind: "acclimatisation")
    @plant.move_to!(box)
    assert_not @plant.current_assignment.context_offer?
  end

  test "repotting changes the current setup while earlier events show the earlier setup" do
    @plant.change_setup!({ container: "Nursery pot", size: 12, size_unit: "cm", watering_method: "top" }, on: 20.days.ago.to_date)
    @plant.move_to!(@shelf, on: 20.days.ago.to_date)
    observation = @plant.care_events.create!(user: @user, note: "Roots out the bottom", occurred_at: 10.days.ago, idempotency_key: "obs")
    @plant.change_setup!({ container: "Terracotta pot", size: 15, size_unit: "cm", watering_method: "bottom" }, on: 5.days.ago.to_date)

    assert_equal "Terracotta pot", @plant.current_setup.container
    environment, setup = @plant.reload.setting_on(observation.occurred_at.to_date)
    assert_equal @shelf, environment
    assert_equal "Nursery pot", setup.container
    assert_equal 2, @plant.care_events.setup.count
  end

  test "a setup needs something recorded" do
    assert_raises(ActiveRecord::RecordInvalid) { @plant.change_setup!({ container: "" }) }
  end

  test "a blank reading stays unknown and every value has a unit, date and source" do
    reading = @user.measurements.new(environment: @shelf, measured_at: 1.hour.ago, source: "", idempotency_key: "r1")
    reading.assign_readings(fixed: { "air_temperature" => "22,5", "humidity" => "" })
    reading.save!

    assert_equal [ "air_temperature" ], reading.values.map(&:metric)
    value = reading.values.first
    assert_equal BigDecimal("22.5"), value.value
    assert_equal "°C", value.unit
    assert_equal "Manual", reading.source
    assert_equal "22.5°C", value.display_value
  end

  test "readings refuse empty forms, slips and values the type doesn't offer" do
    empty = @user.measurements.new(environment: @shelf, measured_at: Time.current, idempotency_key: "r2")
    empty.assign_readings(fixed: { "humidity" => " " })
    assert_not empty.valid?

    slip = @user.measurements.new(environment: @shelf, measured_at: Time.current, idempotency_key: "r3")
    slip.assign_readings(fixed: { "humidity" => "650", "air_temperature" => "warm" })
    assert_not slip.valid?
    assert_includes slip.errors.full_messages, "Humidity must be between 0 and 100"
    assert_includes slip.errors.full_messages, "Air temperature must be a number"

    assert_equal %w[ water_temperature ph gh kh light_hours light_lux light_ppfd co2_note ], Measurement.metrics_for(@tank).keys
    assert_not_includes Measurement.metrics_for(@shelf).keys, "ph"
  end

  test "custom readings are created once and reused" do
    reading = @user.measurements.new(environment: @tank, measured_at: Time.current, idempotency_key: "r4")
    reading.assign_readings(new_custom: [ { name: "TDS", unit: "ppm", value: "180" } ])
    reading.save!
    tds = @user.custom_metrics.sole
    assert_equal "180 ppm", reading.values.sole.display_value

    again = @user.measurements.new(environment: @tank, measured_at: Time.current, idempotency_key: "r5")
    again.assign_readings(custom: { tds.id.to_s => "190" }, new_custom: [ { name: "tds", unit: "ppm", value: "191" } ])
    assert_not again.valid?, "the same metric twice in one reading"
    assert_equal 1, @user.custom_metrics.count
  end

  test "latest values pick the newest reading per metric" do
    [ [ 3.days.ago, "20" ], [ 1.day.ago, "23" ] ].each_with_index do |(time, temperature), index|
      reading = @user.measurements.new(environment: @shelf, measured_at: time, idempotency_key: "l#{index}")
      reading.assign_readings(fixed: { "air_temperature" => temperature, "humidity" => (index.zero? ? "70" : "") })
      reading.save!
    end

    latest = @shelf.latest_values.index_by(&:metric)
    assert_equal BigDecimal("23"), latest["air_temperature"].value
    assert_equal BigDecimal("70"), latest["humidity"].value
  end

  test "an environment that has held a plant can be archived but not deleted" do
    @plant.move_to!(@shelf, on: 2.days.ago.to_date)
    assert_raises(Environment::NotArchivable) { @shelf.archive! }

    @plant.move_to!(nil)
    @shelf.archive!
    assert @shelf.archived?
    assert_not @shelf.deletable?
    assert_raises(Plant::Placement::MoveRefused) { plants(:monstera_two).move_to!(@shelf) }
    assert @tank.deletable?
  end

  test "deleting a plant removes its moves and setups but keeps the environment" do
    @plant.move_to!(@shelf)
    @plant.change_setup!({ container: "Jar" })
    @plant.destroy!

    assert_empty EnvironmentAssignment.where(plant_id: @plant.id)
    assert_empty PlantSetup.where(plant_id: @plant.id)
    assert Environment.exists?(@shelf.id)
  end
end
