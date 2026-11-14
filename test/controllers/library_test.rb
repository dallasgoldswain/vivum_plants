require "test_helper"

class LibraryTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ collection.plants care.logs care.reminders care.guidance_settings library.profiles care.library_guidance help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @user = users(:collector)
    sign_in_as @user
  end

  test "library pages are hidden while the flag is off" do
    Flipper.disable("library.profiles")
    get library_profiles_path
    assert_response :not_found
    get plant_path(plants(:monstera_one))
    assert_select "#library", 0
  end

  test "the platform library lists published profiles and never drafts (D141, D153)" do
    get platform_profiles_path
    assert_select "a", text: /Monstera deliciosa/
    assert_select "a", text: /Asplenium nidus/, count: 0
    get platform_profile_path(library_profiles(:fern_draft))
    assert_response :not_found
  end

  test "copying a platform profile makes one in your library to edit (D150)" do
    assert_difference -> { @user.library_profiles.count }, 1 do
      post platform_profile_copy_path(library_profiles(:monstera_platform))
    end
    copy = @user.library_profiles.order(:id).last
    assert_redirected_to library_profile_path(copy)

    patch library_profile_path(copy), params: { library_profile: { botanical_name: "Monstera deliciosa", content_params: { indoor: { notes: { light: "East window" }, reminders: { "0" => { kind: "watering", interval: "5", interval_unit: "day" } } } } } }
    assert_equal "East window", copy.reload.notes_for("indoor")["light"]
    assert_equal "Bright, indirect light.", library_profiles(:monstera_platform).reload.notes_for("indoor")["light"]
  end

  test "a blank profile can be created, and a profile with linked plants can't be deleted" do
    post library_profiles_path, params: { library_profile: { botanical_name: "Hoya carnosa", synonym_list: "Wax plant, Hoya" } }
    profile = @user.library_profiles.find_by!(botanical_name: "Hoya carnosa")
    assert_equal [ "Wax plant", "Hoya" ], profile.synonyms

    plants(:monstera_one).update!(library_profile: profile)
    delete library_profile_path(profile)
    assert LibraryProfile.exists?(profile.id)
  end

  test "someone else's profile isn't found" do
    get library_profile_path(library_profiles(:owner_philodendron))
    assert_response :not_found
    post plant_library_link_path(plants(:monstera_one)), params: { library_profile_id: library_profiles(:owner_philodendron).id }
    assert_response :not_found
  end

  test "a platform-only match offers copy and link (D151)" do
    plant = plants(:monstera_one)
    get plant_path(plant)
    assert_select "#library button", "Copy it to your library and link it"

    post plant_library_link_path(plant), params: { platform_profile_id: library_profiles(:monstera_platform).id }
    assert_equal @user, plant.reload.library_profile.user
  end

  test "a match in your library offers to link it, and unlinking keeps reminders" do
    plant = plants(:anubias)
    get plant_path(plant)
    assert_select "#library button", "Link this plant to it"
    post plant_library_link_path(plant), params: { library_profile_id: library_profiles(:collector_anubias).id }
    assert_equal library_profiles(:collector_anubias), plant.reload.library_profile

    plant.update!(guidance_library: true)
    post plant_library_suggestions_path(plant), params: { kind: "inspection", label: "" }
    delete plant_library_link_path(plant)
    assert_nil plant.reload.library_profile
    assert_equal 1, plant.care_schedules.running.count
  end

  test "suggestions show only with the switch on, name their profile, and nothing changes before accepting (GU03)" do
    plant = plants(:anubias)
    plant.update!(library_profile: library_profiles(:collector_anubias))
    get plant_path(plant)
    assert_select "#library input[type=submit][value=Accept]", 0

    plant.update!(guidance_library: true)
    assert_no_difference -> { CareSchedule.count } do
      get plant_path(plant)
    end
    assert_select "#library", /Your profile: Anubias barteri/
    assert_select "#library dd", "Low light."
    assert_select "#library input[type=submit][value=Accept]", 1
  end

  test "accepting an edited suggestion creates the reminder with its source" do
    plant = linked_anubias
    post plant_library_suggestions_path(plant), params: { kind: "inspection", label: "", interval: "10", interval_unit: "day" }
    schedule = plant.care_schedules.sole
    assert_equal [ "library", library_profiles(:collector_anubias), 10, "day" ], [ schedule.origin, schedule.library_profile, schedule.interval, schedule.interval_unit ]
    assert schedule.open_task

    get plant_path(plant)
    assert_select "#library input[type=submit][value=Accept]", 0
    assert_select "#library", /dealt with every suggested reminder/
  end

  test "a suggestion over an existing reminder shows the comparison and replaces it (D145)" do
    plant = linked_anubias
    old = @user.care_schedules.create!(plant: plant, kind: "inspection", interval: 1, interval_unit: "month", starts_on: Date.current).tap(&:start!)
    get plant_path(plant)
    assert_select "#library", /You already have this reminder. Now: every month after it's done. Suggested: every 2 weeks./
    assert_select "#library input[value='Replace reminder']"

    post plant_library_suggestions_path(plant), params: { kind: "inspection", label: "" }
    assert old.reload.ended?
    assert_equal 2, plant.care_schedules.running.sole.interval
  end

  test "dismissing hides a suggestion until the profile is edited" do
    plant = linked_anubias
    post plant_library_dismissals_path(plant), params: { kind: "inspection", label: "" }
    assert_empty plant.reload.library_suggestions.pending

    travel 1.minute do
      library_profiles(:collector_anubias).update!(content_params: { aquatic: { reminders: { "0" => { kind: "inspection", interval: "3", interval_unit: "week" } } } })
      assert_equal 1, plant.reload.library_suggestions.pending.size
    end
  end

  test "editing your profile keeps accepted reminders and flags linked plants (D152)" do
    plant = linked_anubias
    post plant_library_suggestions_path(plant), params: { kind: "inspection", label: "" }
    schedule = plant.care_schedules.sole

    travel 1.minute do
      patch library_profile_path(library_profiles(:collector_anubias)), params: { library_profile: { botanical_name: "Anubias barteri", content_params: { aquatic: { reminders: { "0" => { kind: "inspection", interval: "1", interval_unit: "week" } } } } } }
      assert_equal 2, schedule.reload.interval
      get plant_path(plant)
      assert_select "#library .alert h3", "The Anubias barteri profile was edited"
      assert_select "#library", /Changed in your profile/

      post plant_library_dismissals_path(plant), params: { kind: "inspection", label: "" }
      get plant_path(plant)
      assert_select "#library .alert", 0
      assert schedule.reload.active?
    end
  end

  test "turning the library off for a plant hides suggestions and keeps accepted reminders" do
    plant = linked_anubias
    post plant_library_suggestions_path(plant), params: { kind: "inspection", label: "" }
    patch plant_guidance_path(plant), params: { library: "0" }
    get plant_path(plant)
    assert_select "#library", /Turn on library suggestions/
    assert plant.care_schedules.sole.active?
  end

  test "Today asks once whether to use library suggestions (D146)" do
    get root_path
    assert_select "#library-choice h2", "Use library care suggestions?"
    post library_choice_path, params: { use_library: "1" }
    assert_redirected_to new_guidance_application_path(status: "all")
    assert @user.reload.guidance_defaults.library
    get root_path
    assert_select "#library-choice", 0
  end

  test "No on the Today card changes nothing" do
    post library_choice_path, params: { use_library: "0" }
    assert_not @user.reload.guidance_defaults.library
    assert @user.library_choice_at
  end

  test "Today lists plants with suggestions to review" do
    @user.update!(library_choice_at: Time.current)
    linked_anubias
    get root_path
    assert_select "#library-suggestions a", "Anubias"
  end

  private
    def linked_anubias
      plants(:anubias).tap { it.update!(library_profile: library_profiles(:collector_anubias), guidance_library: true) }
    end
end
