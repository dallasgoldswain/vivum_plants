require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  test "sign-in pages use the auth layout without the app shell" do
    get new_session_path

    assert_response :success
    assert_select "section.vv-bg-auth"
    assert_select ".vv-sidebar", count: 0
  end

  test "signed-in users get the sidebar and mobile nav, both with sign out" do
    sign_in_as users(:packer)
    get root_path

    assert_select ".vv-sidebar a[aria-current=page]", text: "Home"
    assert_select ".vv-sidebar", text: /Fern & Frond/
    assert_select ".vv-bottom-nav button", text: "Sign out"
    assert_select ".vv-sidebar a", text: "Management", count: 0
  end

  test "operators see the management link" do
    users(:owner).update!(platform_operator: true)
    sign_in_as users(:owner)
    get root_path

    assert_select ".vv-sidebar a[href=?]", madmin_root_path, text: "Management"
  end
end
