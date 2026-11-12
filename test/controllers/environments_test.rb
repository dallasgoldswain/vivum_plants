require "test_helper"

class EnvironmentsTest < ActionDispatch::IntegrationTest
  setup do
    %w[ collection.plants collection.search collection.media collection.environments collection.measurements help.manual help.contextual ].each { Flipper.enable(it) }
    @user = users(:collector)
    @shelf, @tank = environments(:shelf), environments(:tank)
    sign_in_as @user
  end

  test "environments are hidden while their flag is off" do
    Flipper.disable("collection.environments")
    get environments_path
    assert_response :not_found
    get plant_path(plants(:monstera_one))
    assert_select "#placement", 0
  end

  test "someone else's environment is not found" do
    get environment_path(environments(:owner_cabinet))
    assert_response :not_found
    post environment_measurements_path(environments(:owner_cabinet)), params: { measurement: { values: { humidity: "60" } } }
    assert_response :not_found
    post plant_moves_path(plants(:monstera_one)), params: { move: { environment_id: environments(:owner_cabinet).id } }
    assert_response :not_found
  end

  test "editing an environment" do
    get edit_environment_path(@shelf)
    assert_response :success
    patch environment_path(@shelf), params: { environment: { name: "Lounge shelf 3" } }
    assert_equal "Lounge shelf 3", @shelf.reload.name
  end

  test "adding an environment with only a name and type" do
    get environments_path
    assert_select "h1", "Environments"

    assert_difference -> { @user.environments.count } do
      post environments_path, params: { environment: { name: "Nano tank", kind: "aquarium" } }
    end
    environment = @user.environments.order(:id).last
    assert_redirected_to environment_path(environment)
    follow_redirect!
    assert_select "h1", /Nano tank/

    post environments_path, params: { environment: { name: "", kind: "aquarium" } }
    assert_response :unprocessable_entity
  end

  test "moving several plants with one date from the environment page" do
    on = 3.days.ago.to_date
    post environment_moves_path(@tank), params: { move: { plant_ids: plants(:monstera_one, :monstera_two, :anubias).map(&:id), moved_on: on.iso8601 } }
    assert_redirected_to environment_path(@tank)

    assert_equal 3, @tank.current_plants.count
    assert_equal [ on ], @tank.current_assignments.map(&:started_on).uniq

    get environment_path(@tank)
    assert_select "h3", "Change their growing context?"
    patch environment_context_offer_path(@tank), params: { answer: "change" }
    assert_equal %w[ aquatic aquatic ], plants(:monstera_one, :monstera_two).map { it.reload.growing_context }
  end

  test "moving one plant from its page, answering the offer and taking it out" do
    plant = plants(:monstera_one)
    post plant_moves_path(plant), params: { move: { environment_id: @tank.id, moved_on: Date.current.iso8601 } }
    assert_redirected_to plant_path(plant, anchor: "placement")
    follow_redirect!
    assert_select "#placement h3", "Change its growing context?"

    patch plant_context_offer_path(plant), params: { answer: "keep" }
    assert_equal "indoor", plant.reload.growing_context
    follow_redirect!
    assert_select "#placement h3", 0

    post plant_moves_path(plant), params: { move: { environment_id: "", moved_on: Date.current.iso8601 } }
    assert_nil plant.reload.current_environment
    follow_redirect!
    assert_match "Not in an environment", response.body
    assert_select ".vv-timeline li", text: /Moved/, count: 2
  end

  test "a refused move explains why" do
    plant = plants(:monstera_one)
    plant.move_to!(@shelf, on: 2.days.ago.to_date)
    post plant_moves_path(plant), params: { move: { environment_id: @tank.id, moved_on: 5.days.ago.to_date.iso8601 } }
    assert_match "choose that date or later", flash[:alert]
  end

  test "changing the setup" do
    plant = plants(:monstera_one)
    post plant_setups_path(plant), params: { plant_setup: { container: "Terracotta pot", size: "15", size_unit: "cm", watering_method: "bottom", started_on: Date.current.iso8601 } }
    assert_equal "Terracotta pot", plant.current_setup.container
    follow_redirect!
    assert_match "Terracotta pot · 15 cm · Bottom watering", response.body

    post plant_setups_path(plant), params: { plant_setup: { container: "", size: "", started_on: Date.current.iso8601 } }
    assert_match "Add a container", flash[:alert]
  end

  test "a reading saves once per key, and answers JSON for the offline queue" do
    params = { measurement: { idempotency_key: "offline-1", measured_at: 1.hour.ago.iso8601, source: "Hygrometer", values: { air_temperature: "24", humidity: "" } } }
    assert_difference -> { @shelf.measurements.count } do
      post environment_measurements_path(@shelf), params: params, as: :json
      post environment_measurements_path(@shelf), params: params, as: :json
    end
    assert_response :created
    assert_equal "Hygrometer", @shelf.measurements.sole.source

    post environment_measurements_path(@shelf), params: { measurement: { idempotency_key: "offline-2", values: { humidity: "650" } } }, as: :json
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"], "Humidity must be between 0 and 100"

    get environment_path(@shelf)
    assert_select "#conditions dd", /24°C/
  end

  test "readings are hidden without the measurements flag" do
    Flipper.disable("collection.measurements")
    get environment_path(@shelf)
    assert_select "#conditions", 0
    post environment_measurements_path(@shelf), params: { measurement: { values: { humidity: "60" } } }
    assert_response :not_found
  end

  test "environment photos count toward the collection cap" do
    post environment_photos_path(@tank), params: { photo: { images: [ fixture_file_upload("leaf.jpg", "image/jpeg") ] } }
    assert_redirected_to environment_path(@tank, anchor: "photos")
    photo = @tank.photos.sole
    assert_equal photo, @tank.reload.cover_photo
    assert_equal 1, Photo.quota_for(@user).used
  end

  test "archiving needs an empty environment; deleting needs one that never held a plant" do
    plant = plants(:monstera_one)
    plant.move_to!(@shelf, on: 2.days.ago.to_date)
    post environment_archive_path(@shelf)
    assert_match "Move or remove its plants first", flash[:alert]

    plant.move_to!(nil)
    post environment_archive_path(@shelf)
    assert @shelf.reload.archived?
    get environments_path
    assert_select "a[href=?]", environment_path(@shelf), count: 0

    get new_environment_deletion_path(@shelf)
    assert_redirected_to environment_path(@shelf)

    get new_environment_deletion_path(@tank)
    assert_response :success
    assert_difference -> { Environment.count }, -1 do
      post environment_deletion_path(@tank)
    end
  end

  test "the collection filters by environment" do
    plants(:anubias).move_to!(@tank)
    get plants_path(environment: @tank.id)
    assert_select ".vv-plant-card", 1
    get plants_path(environment: "none")
    assert_select ".vv-plant-card", 2
  end
end
