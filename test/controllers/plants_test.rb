require "test_helper"

class PlantsTest < ActionDispatch::IntegrationTest
  setup do
    %w[ collection.plants collection.search collection.media collection.acquisition help.manual help.contextual ].each { Flipper.enable(it) }
    @user = users(:collector)
    sign_in_as @user
  end

  test "the collection is hidden while its flag is off" do
    Flipper.disable("collection.plants")
    get plants_path
    assert_response :not_found
  end

  test "the collection lists active plants with search and filters" do
    get plants_path
    assert_response :success
    assert_select ".vv-plant-card", 3
    assert_select "a[href=?]", plant_path(plants(:old_fern)), count: 0

    get plants_path(q: "thai")
    assert_select ".vv-plant-card", 2

    get plants_path(status: "inactive", view: "list")
    assert_select ".vv-plant-row", 1
  end

  test "an empty collection offers to add a plant" do
    sign_in_as users(:manager)
    get plants_path
    assert_select "h2", "Start your collection"
  end

  test "adding a plant with acquisition details" do
    assert_difference -> { @user.plants.count } do
      post plants_path, params: { plant: { display_name: "Alocasia", growing_context: "indoor", tag_list: "aroid", acquisition_attributes: { source: "Swap meet", cost: "80", currency: "ZAR" } } }
    end
    plant = @user.plants.order(:number).last
    assert_redirected_to plant_path(plant)
    follow_redirect!
    assert_select "h1", /Alocasia/
    assert_match "ZAR 80.00", response.body
  end

  test "an invalid plant shows the form again" do
    post plants_path, params: { plant: { display_name: "", growing_context: "" } }
    assert_response :unprocessable_entity
  end

  test "someone else's plant is not found" do
    get plant_path(plants(:owner_philodendron))
    assert_response :not_found

    post plant_care_events_path(plants(:owner_philodendron)), params: { care_event: { note: "x" } }
    assert_response :not_found
  end

  test "editing keeps the record number" do
    patch plant_path(plants(:monstera_one)), params: { plant: { display_name: "Thai Con" } }
    assert_redirected_to plant_path(plants(:monstera_one))
    assert_equal "P-0001", plants(:monstera_one).reload.record_id
  end

  test "changing status with a date and reason" do
    post plant_status_changes_path(plants(:monstera_two)), params: { plant_status_change: { status: "sold", effective_on: Date.yesterday.iso8601, reason: "To a friend" } }
    plant = plants(:monstera_two).reload
    assert_equal "sold", plant.status
    assert_equal Date.yesterday, plant.status_on

    get plants_path
    assert_select "a[href=?]", plant_path(plant), count: 0
  end

  test "an observation synced twice saves once" do
    params = { care_event: { note: "New root", occurred_at: 1.day.ago.strftime("%Y-%m-%dT%H:%M"), idempotency_key: "offline-123" } }

    assert_difference -> { CareEvent.count }, 1 do
      post plant_care_events_path(plants(:anubias)), params: params, headers: { "Accept" => "application/json" }
      post plant_care_events_path(plants(:anubias)), params: params, headers: { "Accept" => "application/json" }
    end
    assert_response :created
    assert_equal 1.day.ago.to_date, CareEvent.last.occurred_at.to_date
  end

  test "an observation with a photo, and a refused photo keeps the note" do
    post plant_care_events_path(plants(:anubias)), params: { care_event: { note: "Pearling", idempotency_key: "a", photos: [ photo_upload ] } }
    assert_redirected_to plant_path(plants(:anubias))
    assert_equal 1, CareEvent.find_by(idempotency_key: "a").photos.count

    stub_const(Photo, :COLLECTOR_LIMIT, 1) do
      post plant_care_events_path(plants(:anubias)), params: { care_event: { note: "Kept", idempotency_key: "b", photos: [ photo_upload ] } }, headers: { "Accept" => "application/json" }
      assert_response :created
      assert_match "reached your 1 photos", response.parsed_body["rejected_photos"].first
      assert_equal "Kept", CareEvent.find_by(idempotency_key: "b").note
    end
  end

  test "an empty observation is refused" do
    post plant_care_events_path(plants(:anubias)), params: { care_event: { note: "", idempotency_key: "c" } }, headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity
  end

  test "adding, covering and deleting photos" do
    post plant_photos_path(plants(:monstera_one)), params: { photo: { images: [ photo_upload, photo_upload ], caption: "Variegation" } }
    assert_redirected_to plant_path(plants(:monstera_one), anchor: "photos")
    first, second = plants(:monstera_one).photos.order(:id).to_a
    assert_equal first, plants(:monstera_one).reload.cover_photo

    post cover_plant_photo_path(plants(:monstera_one), second)
    assert_equal second, plants(:monstera_one).reload.cover_photo

    delete plant_photo_path(plants(:monstera_one), second)
    assert_nil plants(:monstera_one).reload.cover_photo
    assert_equal 1, @user.photos.count

    get plant_path(plants(:monstera_one))
    assert_response :success
    assert_match "1 of 500 photos", response.body
  end

  test "permanent deletion warns with counts first" do
    plants(:anubias).care_events.create!(user: @user, note: "x", occurred_at: Time.current, idempotency_key: "d")

    get new_plant_deletion_path(plants(:anubias))
    assert_match "1 observation", response.body

    assert_difference -> { @user.plants.count }, -1 do
      post plant_deletion_path(plants(:anubias))
    end
    assert_redirected_to plants_path
  end

  test "pages link to their help topics" do
    get plants_path
    assert_select "a.vv-help-link[href=?]", help_topic_path("collection")
    get plant_path(plants(:anubias))
    assert_select "a.vv-help-link[href=?]", help_topic_path("observations-and-photos")
  end

  test "the service worker is served" do
    get pwa_service_worker_path(format: :js)
    assert_response :success
    assert_match "vivum-pages", response.body
  end

  private
    def photo_upload
      Rack::Test::UploadedFile.new(file_fixture("leaf.jpg"), "image/jpeg")
    end
end
