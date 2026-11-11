require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @plant = plants(:monstera_one)
  end

  test "uploads are resized to 2560 px and stripped of location and other metadata" do
    photo = Photo.build_from_upload(upload("leaf.jpg", "image/jpeg"), user: @user, plant: @plant)
    photo.save!

    image = Vips::Image.new_from_buffer(photo.image.download, "")
    assert_equal 2560, [ image.width, image.height ].max
    assert_empty image.get_fields.grep(/exif|gps|xmp|iptc/i)
    assert_equal "image/jpeg", photo.image.content_type
  end

  test "the first photo becomes the cover" do
    photo = Photo.build_from_upload(upload("leaf.jpg", "image/jpeg"), user: @user, plant: @plant)
    photo.save!
    assert_equal photo, @plant.reload.cover_photo
  end

  test "files that aren't photos are refused" do
    error = assert_raises(Photo::Rejected) do
      Photo.build_from_upload(upload("not_a_photo.txt", "image/jpeg", name: "notes.jpg"), user: @user, plant: @plant)
    end
    assert_match "JPEG, PNG or WebP", error.message
  end

  test "a full collection refuses new photos, and deleting one frees space" do
    stub_const(Photo, :COLLECTOR_LIMIT, 1) do
      first = Photo.build_from_upload(upload("leaf.jpg", "image/jpeg"), user: @user, plant: @plant)
      first.save!
      assert Photo.quota_for(@user).full?

      assert_raises(Photo::Rejected) { Photo.build_from_upload(upload("leaf.jpg", "image/jpeg"), user: @user, plant: @plant) }

      first.destroy!
      assert_not Photo.quota_for(@user).full?
    end
  end

  test "the quota warns from 80%" do
    assert Photo::Quota.new(used: 400, limit: 500).warning?
    assert_not Photo::Quota.new(used: 399, limit: 500).warning?
  end

  private
    def upload(fixture, type, name: nil)
      path = file_fixture(fixture)
      Rack::Test::UploadedFile.new(path, type, original_filename: name || File.basename(path))
    end
end
