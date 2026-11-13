require "test_helper"

class GuidanceTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
  end

  test "plant A keeps revision 1 after revision 2 is saved; plant B gets revision 2 (ST02)" do
    a = @user.plants.create!(display_name: "A", growing_context: "indoor")
    first = @user.guidance_defaults
    assert_equal [ first, false ], [ a.guidance_revision, a.guidance_library ]

    second = @user.save_guidance_defaults!(library: true)
    assert_equal 2, second.number
    b = @user.plants.create!(display_name: "B", growing_context: "indoor")

    assert_equal [ first, false, :older ], [ a.reload.guidance_revision, a.guidance_library, a.guidance_status ]
    assert_equal [ second, true, :matches ], [ b.guidance_revision, b.guidance_library, b.guidance_status ]
  end

  test "saving unchanged defaults adds no revision" do
    assert_no_difference -> { @user.guidance_revisions.count } do
      @user.save_guidance_defaults!(library: false)
    end
  end

  test "a new account starts at revision 1 with both off (D15)" do
    user = User.create!(email_address: "new@example.com", password: "password-long-enough")
    defaults = user.guidance_defaults
    assert_equal [ 1, false, false ], [ defaults.number, defaults.library, defaults.ai ]
  end

  test "changing one plant changes no other plant or the defaults (ST01)" do
    plant = plants(:monstera_one)
    plant.update!(guidance_library: true)
    assert_equal :changed, plant.guidance_status
    assert_not plants(:monstera_two).reload.guidance_library
    assert_not @user.guidance_defaults.library
  end

  test "applying defaults changes only the switches, not reminders or history (ST04)" do
    plant = plants(:monstera_one)
    schedule = @user.care_schedules.create!(plant: plant, kind: "watering", interval: 7, interval_unit: "day", starts_on: Date.current).tap(&:start!)
    @user.save_guidance_defaults!(library: true)

    assert_no_difference -> { plant.care_events.count } do
      plant.apply_guidance_defaults!
    end
    assert_equal [ true, :matches ], [ plant.guidance_library, plant.guidance_status ]
    assert schedule.reload.active?
  end

  test "TC plantlets take the defaults and a split copies its source (D138)" do
    @user.save_guidance_defaults!(library: true)
    plantlet = TissueCulture::Purchase.new(user: @user, name: "TC", quantity: 1).tap(&:save).acquisition.plants.sole
    assert plantlet.guidance_library

    source = plants(:anubias)
    source.update!(quantity: 4)
    part = source.split!([ 2 ]).sole
    assert_equal [ users(:collector).guidance_revisions.find_by!(number: 1), false ], [ part.guidance_revision, part.guidance_library ]
    assert_equal :older, part.guidance_status
  end
end
