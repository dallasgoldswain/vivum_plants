require "test_helper"

# The collection (plants, observations, photos, environments, setups and readings) is in the
# account export and gone after deletion (B08).
class CollectionPrivacyTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @plant = plants(:monstera_one)
    @plant.care_events.create!(user: @user, note: "First leaf", occurred_at: Time.current, idempotency_key: "e")
    Photo.build_from_upload(Rack::Test::UploadedFile.new(file_fixture("leaf.jpg"), "image/jpeg"), user: @user, plant: @plant).save!

    @tank = environments(:tank)
    @plant.move_to!(@tank, on: 2.days.ago.to_date)
    @plant.change_setup!({ container: "Glass jar" })
    reading = @user.measurements.new(environment: @tank, measured_at: 1.hour.ago, idempotency_key: "m")
    reading.assign_readings(fixed: { "ph" => "6.8" }, new_custom: [ { name: "TDS", unit: "ppm", value: "180" } ])
    reading.save!
    Photo.build_from_upload(Rack::Test::UploadedFile.new(file_fixture("leaf.jpg"), "image/jpeg"), user: @user, environment: @tank).save!
    @plant.change_setup!({ recipe_version_id: recipe_versions(:aroid_v1).id })
    ingredients(:bark).copy_for!(@user)
  end

  test "the export holds plants, observations and photo files" do
    entries = {}
    Zip::InputStream.open(StringIO.new(AccountExport.new(@user).to_zip)) do |zip|
      while (entry = zip.get_next_entry)
        entries[entry.name] = zip.read
      end
    end

    plants = JSON.parse(entries["plants.json"])
    assert_equal %w[ P-0001 P-0002 P-0003 P-0004 ], plants.map { it["record_id"] }
    events = JSON.parse(entries["care_events.json"])
    assert_equal "First leaf", events.find { it["kind"] == "observation" }["note"]
    assert_equal "60 cm tank", events.find { it["kind"] == "movement" }["moved_to"]
    photo = JSON.parse(entries["photos.json"]).first
    assert entries[photo["file"]].bytesize.positive?
    assert_not_includes entries["plants.json"], "Philodendron", "another user's plants"

    tank = JSON.parse(entries["environments.json"]).find { it["name"] == "60 cm tank" }
    assert_equal "P-0001", tank["occupants"].sole["plant"]
    assert_equal "Glass jar", JSON.parse(entries["plant_setups.json"]).first["container"]
    assert_equal [ "pH", "TDS" ], JSON.parse(entries["measurements.json"]).sole["values"].map { it["metric"] }
    assert_equal "TDS", JSON.parse(entries["custom_metrics.json"]).sole["name"]
    environment_photo = JSON.parse(entries["photos.json"]).find { it["environment"] }
    assert entries[environment_photo["file"]].bytesize.positive?
    assert_not_includes entries["environments.json"], "Grow cabinet", "another user's environments"

    assert_equal [ "Aroid mix", 1 ], JSON.parse(entries["plant_setups.json"]).last.values_at("recipe", "recipe_version")
    recipe = JSON.parse(entries["recipes.json"]).sole
    assert_equal [ 2, 1, 1 ], recipe["versions"].sole["components"].map { it["quantity"].to_i }
    assert_equal [ "Orchid bark, medium", "Pumice" ], JSON.parse(entries["ingredients.json"]).map { it["name"] }.sort
    assert_not_includes entries["recipes.json"], "Owner's mix", "another user's recipes"
  end

  test "purging an account removes its plants, observations and photos" do
    @user.update_columns(deletion_requested_at: 31.days.ago)
    @user.purge!

    assert_equal 0, Plant.where(user: @user).count
    assert_equal 0, CareEvent.where(user: @user).count
    assert_equal 0, Photo.where(user: @user).count
    [ Environment, EnvironmentAssignment, PlantSetup, Measurement, CustomMetric, Recipe, Ingredient ].each do |model|
      assert_equal 0, model.where(user: @user).count, model.name
    end
    assert Plant.exists?(plants(:owner_philodendron).id)
    assert Environment.exists?(environments(:owner_cabinet).id)
    assert Recipe.exists?(recipes(:owner_mix).id)
    assert Ingredient.exists?(ingredients(:bark).id), "built-ins stay"
  end
end
