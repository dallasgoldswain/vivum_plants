require "test_helper"

class Madmin::AccessTest < ActionDispatch::IntegrationTest
  test "signed-out visitors are sent to sign in" do
    get madmin_root_path
    assert_redirected_to new_session_path
  end

  test "non-operators get a 404" do
    sign_in_as users(:collector)
    get madmin_root_path
    assert_response :not_found
  end

  test "operators without two-step sign-in must set it up first" do
    user = users(:collector)
    user.update!(platform_operator: true)
    sign_in_as user

    get madmin_root_path
    assert_redirected_to new_two_factor_enrolment_path
  end

  test "operators with two-step sign-in can use the area" do
    operator = users(:owner)
    operator.update!(platform_operator: true)
    sign_in_as operator

    get madmin_root_path
    assert_response :success

    get madmin_users_path
    assert_response :success

    get madmin_user_path(operator)
    assert_response :success
    assert_no_match "JBSWY3DPEHPK3PXP", response.body, "TOTP secret must not be shown"
  end

  test "sessions are read-only" do
    operator = users(:owner)
    operator.update!(platform_operator: true)
    sign_in_as operator
    session_record = users(:collector).sessions.create!

    assert_no_difference -> { Session.count } do
      delete madmin_session_path(session_record)
    end
  end
end
