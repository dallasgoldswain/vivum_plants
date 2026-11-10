require "test_helper"

class SecurityAuditTest < ActionDispatch::IntegrationTest
  # Flipper's test reset removes leftover flags at the start of each test, which is audited
  # too; these tests only look at security events.
  def actions = AuditEvent.where.not("action LIKE 'flag.%'").order(:id).pluck(:action)

  test "a successful sign-in is recorded" do
    post session_path, params: { email_address: "collector@example.com", password: "password-long-enough" }

    event = AuditEvent.find_by!(action: "session.created")
    assert_equal users(:collector), event.actor
    assert event.ip_address.present?
  end

  test "a failed sign-in records the attempted email and no actor" do
    post session_path, params: { email_address: "Someone@Example.com", password: "wrong" }

    event = AuditEvent.find_by!(action: "session.failed")
    assert_nil event.actor_id
    assert_equal "someone@example.com", event.details["email_address"]
  end

  test "two-step sign-in records the password step and the method used" do
    user = users(:owner)
    post session_path, params: { email_address: user.email_address, password: "password-long-enough" }
    post two_factor_challenge_path, params: { code: "000000" }
    post two_factor_challenge_path, params: { code: ROTP::TOTP.new(user.otp_secret).now }

    assert_equal %w[ session.password_verified two_factor.failed session.created ], actions
    assert_equal "totp", AuditEvent.find_by!(action: "session.created").details["second_factor"]
  end

  test "sign-out, password reset and two-step changes are recorded" do
    user = users(:collector)
    post passwords_path, params: { email_address: user.email_address }
    put password_path(user.password_reset_token), params: { password: "a-new-long-password", password_confirmation: "a-new-long-password" }

    sign_in_as user
    get new_two_factor_enrolment_path
    post two_factor_enrolment_path, params: { code: ROTP::TOTP.new(session[:pending_otp_secret]).now }
    delete session_path

    assert_equal %w[ password.reset_requested password.reset_completed two_factor.enabled session.destroyed ], actions
  end
end
