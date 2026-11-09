require "test_helper"

class TwoFactorTest < ActionDispatch::IntegrationTest
  test "correct password then correct code signs in" do
    user = users(:owner)
    post session_path, params: { email_address: user.email_address, password: "password-long-enough" }
    assert_redirected_to new_two_factor_challenge_path

    post two_factor_challenge_path, params: { code: ROTP::TOTP.new(user.otp_secret).now }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "wrong code does not sign in" do
    user = users(:owner)
    post session_path, params: { email_address: user.email_address, password: "password-long-enough" }
    post two_factor_challenge_path, params: { code: "000000" }

    assert_redirected_to new_two_factor_challenge_path
    assert_empty user.sessions
  end

  test "the challenge cannot be reached without a correct password first" do
    get new_two_factor_challenge_path
    assert_redirected_to new_session_path

    post two_factor_challenge_path, params: { code: ROTP::TOTP.new(users(:owner).otp_secret).now }
    assert_redirected_to new_session_path
    assert_empty users(:owner).sessions
  end

  test "owners without two-step sign-in must set it up before using the app" do
    sign_in_as users(:unenrolled_owner)
    get root_path
    assert_redirected_to new_two_factor_enrolment_path
  end

  test "enrolment turns on two-step sign-in and shows backup codes" do
    user = users(:unenrolled_owner)
    sign_in_as user

    get new_two_factor_enrolment_path
    assert_response :success
    secret = session[:pending_otp_secret]

    post two_factor_enrolment_path, params: { code: ROTP::TOTP.new(secret).now }
    assert_response :success
    assert user.reload.two_factor_enabled?
    assert_equal User::BACKUP_CODE_COUNT, user.otp_backup_codes.count

    get root_path
    assert_response :success
  end

  test "enrolment with a wrong code leaves it off" do
    user = users(:unenrolled_owner)
    sign_in_as user
    get new_two_factor_enrolment_path
    post two_factor_enrolment_path, params: { code: "000000" }

    assert_redirected_to new_two_factor_enrolment_path
    assert_not user.reload.two_factor_enabled?
  end

  test "owners cannot turn two-step sign-in off" do
    user = users(:owner)
    sign_in_as user
    delete two_factor_enrolment_path, params: { code: ROTP::TOTP.new(user.otp_secret).now }

    assert user.reload.two_factor_enabled?
  end

  test "optional users can turn it off with a current code" do
    user = users(:collector)
    secret = User.generate_otp_secret
    user.enable_two_factor!(secret)
    sign_in_as user

    delete two_factor_enrolment_path, params: { code: ROTP::TOTP.new(secret).now }
    assert_not user.reload.two_factor_enabled?
  end
end
