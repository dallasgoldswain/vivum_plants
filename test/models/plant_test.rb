require "test_helper"

class PlantTest < ActiveSupport::TestCase
  setup { @user = users(:collector) }

  test "an unknown plant saves with only a name and growing context" do
    plant = @user.plants.create!(display_name: "Mystery cutting", growing_context: "indoor")

    assert_equal "P-0005", plant.record_id
    assert_nil plant.botanical_name
    assert_equal [ "active" ], plant.status_changes.map(&:status)
  end

  test "growing context is required and must be one of the five" do
    assert_not @user.plants.new(display_name: "X").valid?
    assert_not @user.plants.new(display_name: "X", growing_context: "greenhouse").valid?
    Plant::GROWING_CONTEXTS.each { |context| assert @user.plants.new(display_name: "X", growing_context: context).valid? }
  end

  test "record numbers are never reused, even after a delete" do
    plant = @user.plants.create!(display_name: "A", growing_context: "indoor")
    plant.destroy!
    assert_equal "P-0006", @user.plants.create!(display_name: "B", growing_context: "indoor").record_id
  end

  test "renaming keeps the record number and history" do
    plant = plants(:monstera_one)
    plant.care_events.create!(user: @user, note: "New leaf", occurred_at: 1.day.ago, idempotency_key: "k1")

    plant.update!(display_name: "Thai Con")
    assert_equal "P-0001", plant.reload.record_id
    assert_equal 1, plant.care_events.count
  end

  test "a gift saves without a price and a price keeps its currency" do
    gift = @user.plants.create!(display_name: "Gift", growing_context: "indoor", acquisition_attributes: { source: "A friend" })
    assert_nil gift.acquisition.cost_cents
    assert_equal @user, gift.acquisition.user

    bought = @user.plants.create!(display_name: "Bought", growing_context: "indoor", acquisition_attributes: { cost: "12.50", currency: "usd" })
    assert_equal 1250, bought.acquisition.cost_cents
    assert_equal "USD", bought.acquisition.currency
  end

  test "an acquisition with nothing filled in isn't created" do
    plant = @user.plants.create!(display_name: "Plain", growing_context: "indoor", acquisition_attributes: { currency: "ZAR" })
    assert_nil plant.acquisition
  end

  test "deleting the last plant on an acquisition removes the acquisition" do
    plant = @user.plants.create!(display_name: "Bought", growing_context: "indoor", acquisition_attributes: { source: "Nursery" })
    assert_difference -> { Acquisition.count }, -1 do
      plant.destroy!
    end
  end

  test "archiving hides a plant from the active collection but keeps its timeline" do
    plant = plants(:monstera_one)
    plant.care_events.create!(user: @user, note: "Leaf", occurred_at: 2.days.ago, idempotency_key: "k2")

    plant.change_status!("archived", on: Date.yesterday, reason: "Gave up")
    assert_not_includes @user.plants.in_active_collection, plant
    assert_includes @user.plants.filtered(status: "inactive"), plant
    assert_equal %i[ status_change observation ], plant.timeline.map(&:kind)
    assert_equal "Gave up", plant.status_changes.last.reason
  end

  test "yesterday's observation sorts after today's, even when entered later" do
    plant = plants(:anubias)
    today = plant.care_events.create!(user: @user, note: "Today", occurred_at: Time.current, idempotency_key: "t")
    yesterday = plant.care_events.create!(user: @user, note: "Yesterday", occurred_at: 1.day.ago, idempotency_key: "y")

    assert_equal [ today, yesterday ], plant.timeline.select { it.kind == :observation }.map(&:record)
  end

  test "two plants of the same cultivar are found separately" do
    results = @user.plants.search("thai constellation")
    assert_equal [ plants(:monstera_one), plants(:monstera_two) ].sort_by(&:id), results.sort_by(&:id)

    assert_equal [ plants(:monstera_two) ], @user.plants.search("bathroom").to_a
    assert_equal [ plants(:anubias) ], @user.plants.search("P-0003").to_a
    assert_equal [ plants(:anubias) ], @user.plants.search("3").to_a
    assert_equal [ plants(:monstera_one) ], @user.plants.search("rare").to_a
    assert_empty users(:owner).plants.search("monstera")
  end

  test "filters by context, TC origin, tag and status" do
    assert_equal [ plants(:anubias) ], @user.plants.filtered(context: "aquatic").to_a
    assert_equal [ plants(:anubias) ], @user.plants.filtered(tc_origin: "1").to_a
    assert_equal [ plants(:monstera_one) ], @user.plants.filtered(tag: "Rare").to_a
    assert_equal [ plants(:old_fern) ], @user.plants.filtered(status: "archived").to_a
    assert_equal 4, @user.plants.filtered(status: "all").count
  end

  test "tags are typed comma-separated and stored lower-case without repeats" do
    plant = @user.plants.create!(display_name: "T", growing_context: "outdoor", tag_list: "Aroid, rare , aroid,,")
    assert_equal %w[ aroid rare ], plant.tags
    assert_equal %w[ aroid rare ], @user.plant_tags
  end

  test "an observation saves once per idempotency key" do
    plant = plants(:anubias)
    first = CareEvent.record_once(user: @user, plant: plant, idempotency_key: "same", note: "Pearling", occurred_at: Time.current)
    again = CareEvent.record_once(user: @user, plant: plant, idempotency_key: "same", note: "Pearling", occurred_at: Time.current)

    assert_equal first, again
    assert_equal 1, @user.care_events.count
  end

  test "an observation can't be on someone else's plant" do
    event = @user.care_events.new(plant: plants(:owner_philodendron), note: "x", occurred_at: Time.current, idempotency_key: "z")
    assert_not event.valid?
  end
end
