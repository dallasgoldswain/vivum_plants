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

  test "sign up through a referral link credits the referrer" do
    code = users(:collector).referral_codes.create!(code: "fernfriend")

    get new_registration_path(ref: "fernfriend")
    post registration_path, params: { user: { email_address: "referred@example.com", password: "a-long-password", password_confirmation: "a-long-password" } }

    referee = User.find_by!(email_address: "referred@example.com")
    assert_equal users(:collector), referee.referrer
    assert_equal code, referee.referral.referral_code
    assert_empty Refer::Visit.all, "visit tracking is off"
  end

  test "sign up with an unknown referral code still works" do
    get new_registration_path(ref: "no-such-code")
    post registration_path, params: { user: { email_address: "plain@example.com", password: "a-long-password", password_confirmation: "a-long-password" } }

    assert_nil User.find_by!(email_address: "plain@example.com").referral
  end
end
