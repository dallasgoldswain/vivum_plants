require "test_helper"

# Plants, observations and photos are in the account export and gone after deletion (B08).
class CollectionPrivacyTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @plant = plants(:monstera_one)
    @plant.care_events.create!(user: @user, note: "First leaf", occurred_at: Time.current, idempotency_key: "e")
    Photo.build_from_upload(Rack::Test::UploadedFile.new(file_fixture("leaf.jpg"), "image/jpeg"), user: @user, plant: @plant).save!
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
    assert_equal "First leaf", JSON.parse(entries["care_events.json"]).first["note"]
    photo = JSON.parse(entries["photos.json"]).first
    assert entries[photo["file"]].bytesize.positive?
    assert_not_includes entries["plants.json"], "Philodendron", "another user's plants"
  end

  test "purging an account removes its plants, observations and photos" do
    @user.update_columns(deletion_requested_at: 31.days.ago)
    @user.purge!

    assert_equal 0, Plant.where(user: @user).count
    assert_equal 0, CareEvent.where(user: @user).count
    assert_equal 0, Photo.where(user: @user).count
    assert Plant.exists?(plants(:owner_philodendron).id)
  end
end
