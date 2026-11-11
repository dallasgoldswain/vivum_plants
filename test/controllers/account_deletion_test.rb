require "test_helper"

class AccountDeletionControllerTest < ActionDispatch::IntegrationTest
  test "deleting needs the password" do
    sign_in_as users(:collector)

    post settings_account_deletion_path, params: { password: "wrong" }
    assert_redirected_to new_settings_account_deletion_path
    assert_not users(:collector).reload.deletion_pending?
  end

  test "deleting needs the two-step code when it is on" do
    memberships(:fern_manager).update!(role: "owner")
    user = users(:owner)
    sign_in_as user

    post settings_account_deletion_path, params: { password: "password-long-enough", code: "000000" }
    assert_not user.reload.deletion_pending?

    post settings_account_deletion_path, params: { password: "password-long-enough", code: ROTP::TOTP.new(user.otp_secret).now }
    assert user.reload.deletion_pending?
  end

  test "deleting signs out and signing in again offers to keep the account" do
    user = users(:collector)
    sign_in_as user

    post settings_account_deletion_path, params: { password: "password-long-enough" }
    assert_redirected_to new_session_path
    assert user.reload.deletion_pending?

    get root_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: user.email_address, password: "password-long-enough" }
    follow_redirect!
    assert_redirected_to new_deletion_cancellation_path

    get settings_privacy_path
    assert_redirected_to new_deletion_cancellation_path

    post deletion_cancellation_path
    assert_redirected_to root_path
    assert_not user.reload.deletion_pending?
    get root_path
    assert_response :success
  end

  test "the last owner of a seller is told to hand over first" do
    sign_in_as users(:owner)

    get new_settings_account_deletion_path
    assert_match "only owner of", response.body

    post settings_account_deletion_path, params: { password: "password-long-enough", code: ROTP::TOTP.new(users(:owner).otp_secret).now }
    assert_not users(:owner).reload.deletion_pending?
  end

  test "the public deletion help page needs no sign-in" do
    get account_deletion_help_path
    assert_response :success
    assert_match "Delete my account", response.body
  end
end
