require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign up creates an unverified account, signs in and sends a verification email" do
    assert_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "new@example.com", password: "a-long-password", password_confirmation: "a-long-password" } }
    end

    user = User.find_by!(email_address: "new@example.com")
    assert_not user.email_verified?
    assert_enqueued_email_with EmailVerificationMailer, :verify, args: [ user ]
    assert_redirected_to new_email_verification_path
    assert cookies[:session_id]
  end

  test "sign up with invalid details re-renders the form" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "new@example.com", password: "short", password_confirmation: "short" } }
    end
    assert_response :unprocessable_entity
  end

  test "sign up with a taken email fails" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: users(:collector).email_address, password: "a-long-password", password_confirmation: "a-long-password" } }
    end
    assert_response :unprocessable_entity
  end
end
