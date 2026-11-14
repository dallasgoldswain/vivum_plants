require "test_helper"

class Madmin::LibraryProfilesTest < ActionDispatch::IntegrationTest
  setup do
    @operator = users(:owner)
    @operator.update!(platform_operator: true)
    sign_in_as @operator
  end

  test "an operator creates a profile, reviews and publishes it, and every step is audited (D141)" do
    post madmin_library_profiles_path, params: { key: "hoya_carnosa", library_profile_version: { botanical_name: "Hoya carnosa", family: "Apocynaceae", content_params: { indoor: { notes: { light: "Bright" } } } } }
    profile = LibraryProfile.find_by!(key: "hoya_carnosa")
    version = profile.versions.sole
    assert version.draft?
    assert_not LibraryProfile.published.exists?(profile.id)

    post submit_madmin_library_profile_version_path(profile, version)
    post publish_madmin_library_profile_version_path(profile, version)
    assert version.reload.published?
    assert_equal @operator, version.published_by
    assert LibraryProfile.published.exists?(profile.id)
    assert_equal %w[ library.profile_created library.version_submitted library.version_published ], AuditEvent.where("action LIKE 'library.%'").order(:id).pluck(:action)
  end

  test "a published version can't be edited; a new version starts from it" do
    profile = library_profiles(:monstera_platform)
    patch madmin_library_profile_version_path(profile, library_profile_versions(:monstera_v1)), params: { library_profile_version: { botanical_name: "Changed" } }
    assert_equal "Monstera deliciosa", library_profile_versions(:monstera_v1).reload.botanical_name

    get new_madmin_library_profile_version_path(profile)
    assert_response :success
    assert_select "input[name='library_profile_version[botanical_name]'][value='Monstera deliciosa']"
  end

  test "collectors can't reach the editor" do
    sign_in_as users(:collector)
    get madmin_library_profiles_path
    assert_response :not_found
  end
end
