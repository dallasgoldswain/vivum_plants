require "test_helper"

class TissueCultureTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
  end

  test "recording 5 plantlets makes a group with arrival quantity 5 and five numbered records (D127)" do
    numbers_before = @user.plants.maximum(:number)
    purchase = record(quantity: 5)
    group = purchase.acquisition
    assert group.tissue_culture?
    assert_equal 5, group.quantity
    plants = group.plants.order(:number)
    assert_equal (numbers_before + 1..numbers_before + 5).to_a, plants.map(&:number)
    assert_equal [ "Monstera TC 1", "Monstera TC 5" ], [ plants.first.display_name, plants.last.display_name ]
    assert plants.all? { it.tc_origin? && it.tc_stage == "sealed" && it.quantity == 1 }
    assert_equal 5, group.remaining
  end

  test "a pre-deflasked purchase can start at acclimatising, and unknowns are optional" do
    purchase = record(quantity: 1, stage: "acclimatising", source: nil, acquired_on: nil)
    assert_equal "acclimatising", purchase.acquisition.plants.sole.tc_stage
  end

  test "more than 50 plantlets, or none, is refused" do
    assert_not TissueCulture::Purchase.new(user: @user, name: "Big flask", quantity: 51).save
    assert_not TissueCulture::Purchase.new(user: @user, name: "Empty", quantity: 0).save
  end

  test "deflasked → established in an aquarium needs no indoor stage; both stay on the timeline (TC02)" do
    plant = record(quantity: 1, stage: "deflasked", growing_context: "aquatic").acquisition.plants.sole
    plant.change_stage!("established")
    assert plant.tc_established?
    assert_equal %w[ deflasked established ], plant.care_events.where(kind: "stage").order(:id).pluck(:stage)
    assert_equal "aquatic", plant.growing_context
  end

  test "a lost plantlet keeps the arrival quantity and lowers what remains (TC03, D129)" do
    group = record(quantity: 5).acquisition
    group.plants.first.change_status!("lost", reason: "Lost plantlet")
    assert_equal [ 5, 4 ], [ group.reload.quantity, group.remaining ]
  end

  test "an inspection with TC ticks never changes the stage (TC04)" do
    plant = record(quantity: 1, stage: "deflasked").acquisition.plants.sole
    event = @user.care_events.create!(plant: plant, kind: "inspection", new_roots: true, suspected_contamination: true, humidity_setup: "Lid cracked", occurred_at: Time.current, idempotency_key: "c")
    assert event.new_roots? && event.suspected_contamination?
    assert_equal "deflasked", plant.reload.tc_stage
  end

  test "splitting 5 into 2 and 3 never counts 8, links both, and copies only ticked reminders (PL06, D133)" do
    plant = plants(:anubias)
    plant.update!(quantity: 5)
    plant.move_to!(environments(:tank))
    keep = @user.care_schedules.create!(plant: plant, kind: "watering", interval: 7, interval_unit: "day", starts_on: Date.current).tap(&:start!)
    @user.care_schedules.create!(plant: plant, kind: "feeding", interval: 14, interval_unit: "day", starts_on: Date.current).start!

    created = plant.split!([ 3 ], copy_schedules: [ keep ])
    part = created.sole
    assert_equal [ 2, 3 ], [ plant.reload.quantity, part.quantity ]
    assert_equal plant, part.split_from
    assert_equal environments(:tank), part.current_environment
    assert_equal [ "watering" ], part.care_schedules.pluck(:kind)
    assert_not_equal plant.number, part.number
    assert_equal 1, plant.care_events.where(kind: "splitting").count
  end

  test "a split must keep at least one in the source" do
    plant = plants(:anubias)
    plant.update!(quantity: 3)
    assert_raises(Plant::TissueCulture::SplitRefused) { plant.split!([ 3 ]) }
    assert_raises(Plant::TissueCulture::SplitRefused) { plant.split!([ 0 ]) }
  end

  test "suggestions depend on stage and context" do
    terrarium = TissueCulture::Suggestions.for("deflasked", "terrarium").map { it.label || it.kind }
    assert_includes terrarium, "Check readiness for repotting"
    assert_includes terrarium, "Ventilation review"
    aquatic = TissueCulture::Suggestions.for("deflasked", "aquatic").map { it.label || it.kind }
    assert_not_includes aquatic, "Ventilation review"
    assert_empty TissueCulture::Suggestions.for("established", "indoor")
  end

  test "the group stays when its last record is deleted" do
    group = record(quantity: 1).acquisition
    group.plants.sole.destroy!
    assert Acquisition.exists?(group.id)
  end

  private
    def record(quantity:, stage: "sealed", growing_context: "indoor", source: "Lab Co", acquired_on: Date.current)
      TissueCulture::Purchase.new(user: @user, name: "Monstera TC", quantity: quantity, stage: stage, growing_context: growing_context, source: source, acquired_on: acquired_on).tap do |purchase|
        assert purchase.save, purchase.errors.full_messages.to_sentence
      end
    end
end
