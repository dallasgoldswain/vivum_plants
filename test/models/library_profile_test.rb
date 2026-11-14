require "test_helper"

class LibraryProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:collector)
    @platform = library_profiles(:monstera_platform)
  end

  test "only published platform profiles are listed; drafts never are (D141)" do
    assert_equal [ @platform ], LibraryProfile.published.to_a
  end

  test "a copy is the collector's own and a later platform correction leaves it unchanged (D150)" do
    copy = @platform.copy_for!(@user)
    assert_equal [ @user, "Monstera deliciosa" ], [ copy.user, copy.botanical_name ]
    assert copy.content_edited_at

    version = @platform.versions.last.next_draft
    version.content_params = { "indoor" => { "notes" => { "light" => "Changed" } } }
    version.save!
    version.submit!
    version.publish!(by: users(:owner))

    assert_equal "Changed", @platform.reload.notes_for("indoor")["light"]
    assert_equal "Bright, indirect light.", copy.reload.notes_for("indoor")["light"]
    assert_equal %w[ published retired ], @platform.versions.reorder(number: :desc).pluck(:status)
  end

  test "a published version can't be edited" do
    version = library_profile_versions(:monstera_v1)
    assert_not version.update(family: "Other")
  end

  test "matching uses the botanical name or a synonym, ignoring case (D151)" do
    assert_equal [ @platform ], LibraryProfile.published.matching("philodendron PERTUSUM").to_a
    assert_empty LibraryProfile.published.matching("")
  end

  test "content params keep known contexts and complete reminders only, and edits are stamped (D143, D152)" do
    profile = @user.library_profiles.create!(botanical_name: "Hoya carnosa")
    first = profile.content_edited_at
    travel 1.minute do
      profile.update!(content_params: {
        "indoor" => { "notes" => { "light" => " Bright ", "unknown" => "x" }, "reminders" => { "0" => { "kind" => "watering", "interval" => "10", "interval_unit" => "day" }, "1" => { "kind" => "", "interval" => "3" } } },
        "moon" => { "notes" => { "light" => "x" } }
      })
    end
    assert_equal({ "indoor" => { "notes" => { "light" => "Bright" }, "reminders" => [ { "kind" => "watering", "label" => nil, "interval" => 10, "interval_unit" => "day" } ] } }, profile.content)
    assert profile.content_edited_at > first
  end

  test "a reminder without an interval unit or a custom one without a label is refused" do
    profile = @user.library_profiles.new(botanical_name: "Hoya")
    profile.content = { "indoor" => { "reminders" => [ { "kind" => "custom", "interval" => 7, "interval_unit" => "day" } ] } }
    assert_not profile.valid?
  end

  test "a plant links only to its owner's profiles" do
    plant = plants(:monstera_one)
    plant.library_profile = @platform
    assert_not plant.valid?
    plant.library_profile = library_profiles(:owner_philodendron)
    assert_not plant.valid?
  end
end
