require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:unverified) }

  test "unverified users are sent to the check-your-email page" do
    sign_in_as @user
    get root_path
    assert_redirected_to new_email_verification_path
  end

  test "resend sends a new link" do
    sign_in_as @user
    post email_verification_path
    assert_enqueued_email_with EmailVerificationMailer, :verify, args: [ @user ]
  end

  test "a valid link verifies the address" do
    get verify_email_path(@user.generate_token_for(:email_verification))

    assert @user.reload.email_verified?
    assert_redirected_to new_session_path
  end

  test "an invalid link does nothing" do
    get verify_email_path("not-a-token")

    assert_not @user.reload.email_verified?
    assert_redirected_to new_session_path
  end

  test "verified users reach the app" do
    sign_in_as users(:collector)
    get root_path
    assert_response :success
  end
end
