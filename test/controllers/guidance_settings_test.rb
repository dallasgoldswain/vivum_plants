require "test_helper"

class GuidanceSettingsTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants collection.search care.guidance_settings help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    sign_in_as @user
  end

  test "guidance pages are hidden while the flag is off" do
    Flipper.disable("care.guidance_settings")
    get settings_guidance_path
    assert_response :not_found
    get plant_path(plants(:monstera_one))
    assert_select "#guidance", 0
  end

  test "the defaults page shows the library switch with the ST03 warning, and no AI switch (D135)" do
    get settings_guidance_path
    assert_select "input[role=switch][name=library]"
    assert_select "input[name=ai]", 0
    assert_select "dialog#guidance-defaults-warning p", /These settings will apply to plants you add from now on. Existing plants will keep their current settings. You can edit each plant's settings at any time./
    assert_select "dialog#guidance-defaults-warning button", "Cancel"
    assert_select "dialog#guidance-defaults-warning button[form=guidance-defaults]", "Save defaults"
  end

  test "saving defaults adds a revision and leaves existing plants (ST02)" do
    patch settings_guidance_path, params: { library: "1" }
    assert_redirected_to settings_guidance_path
    assert @user.guidance_defaults.library
    assert_not plants(:monstera_one).reload.guidance_library

    follow_redirect!
    assert_select "li", /Library suggestions on.*Current/m
    assert_select "a", "Apply current defaults to existing plants"
  end

  test "an AI value is ignored while the AI switch is hidden" do
    patch settings_guidance_path, params: { library: "0", ai: "1" }
    assert_not @user.guidance_defaults.ai
  end

  test "the plant page shows its status, and changing it affects that plant only (ST01, D139)" do
    plant = plants(:monstera_one)
    get plant_path(plant)
    assert_select "#guidance header p", "Matches your defaults."
    assert_select "#guidance dialog", 0

    patch plant_guidance_path(plant), params: { library: "1" }
    assert plant.reload.guidance_library
    assert_not plants(:monstera_two).reload.guidance_library
    follow_redirect!
    assert_select "#guidance header p", "Changed for this plant."
    assert_select "#guidance dialog td", "On"
  end

  test "applying defaults to one plant shows a comparison and updates only its switches (ST04)" do
    @user.save_guidance_defaults!(library: true)
    plant = plants(:monstera_one)
    get plant_path(plant)
    assert_select "#guidance header p", "From older defaults."
    assert_select "#guidance-apply tbody tr", 1

    post plant_guidance_application_path(plant)
    assert_equal [ true, :matches ], [ plant.reload.guidance_library, plant.guidance_status ]
  end

  test "applying defaults to selected plants ticks the ones behind and applies only the chosen (D140)" do
    @user.save_guidance_defaults!(library: true)
    get new_guidance_application_path
    assert_select "input[name='plant_ids[]'][checked]", 3
    assert_match "Library suggestions: Off → On", response.body

    post guidance_applications_path, params: { plant_ids: [ plants(:monstera_one).id, plants(:anubias).id ] }
    assert_redirected_to plants_path
    assert_equal [ true, false, true ], %i[ monstera_one monstera_two anubias ].map { plants(it).reload.guidance_library }
  end

  test "someone else's plant can't be changed or applied" do
    other = plants(:owner_philodendron)
    patch plant_guidance_path(other), params: { library: "1" }
    assert_response :not_found
    post guidance_applications_path, params: { plant_ids: [ other.id ] }
    assert_not other.reload.guidance_library
  end
end
