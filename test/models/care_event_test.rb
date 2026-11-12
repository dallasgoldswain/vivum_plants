require "test_helper"

class CareEventTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @plant = plants(:monstera_one)
  end

  test "a feeding with no details is saved (UX02)" do
    assert log("feeding").persisted?
  end

  test "details belong to their kind and units to the kind of amount" do
    event = log("watering", amount: 500, amount_unit: "mL", watering_method: "bottom", product: "Seaweed feed", strength: "half")
    assert_equal [ 500, "mL", "bottom", nil, nil ], [ event.amount, event.amount_unit, event.watering_method, event.product, event.strength ]

    assert_not log("watering", amount: 2, amount_unit: "mL/L").persisted?
    assert_not log("feeding", amount: 2).persisted?
    assert log("feeding", product: " Seaweed  feed ", amount: 2, amount_unit: "mL/L", strength: "half").then { it.persisted? && it.product == "Seaweed feed" }
  end

  test "a custom entry needs a label; other kinds don't need a note" do
    assert_not log("custom").persisted?
    assert log("custom", label: "Flushed with RO water").persisted?
    assert_not log("observation").persisted?
  end

  test "products, targets and labels are suggested from earlier entries, latest first (D105)" do
    log("feeding", product: "Seaweed feed", occurred_at: 3.days.ago)
    log("feeding", product: "Bloom booster", occurred_at: 1.day.ago)
    log("treatment", product: "Neem oil", target: "thrips")
    suggestions = CareEvent.suggestions_for(@user)
    assert_equal [ "Neem oil", "Bloom booster", "Seaweed feed" ], suggestions[:product]
    assert_equal [ "thrips" ], suggestions[:target]
    assert_empty CareEvent.suggestions_for(users(:owner))[:product]
  end

  test "last care reports the latest of each main kind (D109)" do
    log("watering", occurred_at: 5.days.ago)
    log("watering", occurred_at: 2.days.ago)
    log("feeding", occurred_at: 10.days.ago)
    log("pruning")
    latest = @plant.last_care
    assert_equal 2.days.ago.to_date, latest["watering"].to_date
    assert_equal 10.days.ago.to_date, latest["feeding"].to_date
    assert_nil latest["pruning"]
  end

  test "a repot writes one repotting event and the new setup from its date (D106)" do
    event = @user.care_events.new(plant: @plant, kind: "repotting", occurred_at: 2.days.ago, idempotency_key: "repot")
    @plant.repot!(event, { container: "Clay pot", size: "14", size_unit: "cm", recipe_version_id: recipe_versions(:aroid_v1).id })

    setup = @plant.reload.current_setup
    assert_equal [ "Clay pot", recipe_versions(:aroid_v1), 2.days.ago.to_date ], [ setup.container, setup.recipe_version, setup.started_on ]
    assert_equal setup, event.plant_setup
    assert_equal [ "repotting" ], @plant.care_events.pluck(:kind)
    assert_not event.deletable?
    assert_not event.date_editable?
  end

  test "a repot with nothing about the pot is just a log" do
    event = @user.care_events.new(plant: @plant, kind: "repotting", occurred_at: Time.current, idempotency_key: "repot")
    @plant.repot!(event, { container: nil, size: nil, size_unit: "cm", recipe_version_id: nil })
    assert event.persisted?
    assert_nil event.plant_setup
    assert event.deletable?
  end

  test "a repot of a draft recipe saves neither the setup nor the event" do
    draft = recipes(:aroid_mix).build_revision(basis: "parts", notes: nil, ready: false, components: [ { ingredient_id: ingredients(:bark).id, quantity: 1 } ])
    recipes(:aroid_mix).save_revision(draft)
    event = @user.care_events.new(plant: @plant, kind: "repotting", occurred_at: Time.current, idempotency_key: "repot")

    assert_raises(ActiveRecord::RecordInvalid) { @plant.repot!(event, { container: "Pot", recipe_version_id: draft.id }) }
    assert_equal 0, @plant.care_events.count
    assert_equal 0, @plant.setups.count
  end

  test "the timeline narrows to one kind, and the collection to plants not watered lately (D109)" do
    log("watering", occurred_at: 8.days.ago)
    log("feeding")
    log("watering", plant: plants(:monstera_two), occurred_at: 2.days.ago)

    assert_equal [ :watering ], @plant.timeline(kind: "watering").map(&:kind)
    dry = @user.plants.filtered(unwatered_days: 7)
    assert_includes dry, @plant
    assert_not_includes dry, plants(:monstera_two)
    assert_includes dry, plants(:anubias), "never watered counts as not watered"
  end

  test "moves and setup changes can't be edited or deleted (D108)" do
    @plant.move_to!(environments(:shelf))
    movement = @plant.care_events.movement.sole
    assert_not movement.editable?
    assert_not movement.deletable?
    assert log("pruning").then { it.editable? && it.deletable? && it.date_editable? }
  end

  private
    def log(kind, plant: @plant, occurred_at: Time.current, **details)
      @user.care_events.create(plant: plant, kind: kind, occurred_at: occurred_at, idempotency_key: SecureRandom.uuid, **details)
    end
end
