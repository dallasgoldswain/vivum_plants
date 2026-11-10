require "test_helper"

class Madmin::FlagsTest < ActionDispatch::IntegrationTest
  test "operators with two-step sign-in can open the flag console" do
    users(:owner).update!(platform_operator: true)
    sign_in_as users(:owner)

    Capabilities.sync!(enable_implemented_core: false)
    get "/madmin/flags/features"
    assert_response :success
    assert_includes response.body, "Stock items, lots and the stock ledger"
    assert_not_includes response.body, "Add Feature", "features come only from config/features.yml"
  end

  test "non-operators get a 404" do
    sign_in_as users(:collector)

    get "/madmin/flags/features"
    assert_response :not_found
  end

  test "operators without two-step sign-in get a 404" do
    users(:collector).update!(platform_operator: true)
    sign_in_as users(:collector)

    get "/madmin/flags/features"
    assert_response :not_found
  end

  test "signed-out visitors get a 404" do
    get "/madmin/flags/features"
    assert_response :not_found
  end
end
