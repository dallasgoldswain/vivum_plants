require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a password of at least 12 characters" do
    user = User.new(email_address: "new@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "email verification token stops working once used" do
    user = users(:unverified)
    token = user.generate_token_for(:email_verification)

    assert_equal user, User.find_by_token_for(:email_verification, token)
    user.verify_email!
    assert_nil User.find_by_token_for(:email_verification, token)
  end

  test "two-step sign-in is required for platform operators and seller owners only" do
    assert users(:owner).two_factor_required?
    assert users(:unenrolled_owner).two_factor_required?
    assert_not users(:manager).two_factor_required?
    assert_not users(:collector).two_factor_required?

    users(:collector).update!(platform_operator: true)
    assert users(:collector).two_factor_required?
  end

  test "otp secret is encrypted at rest" do
    raw = User.connection.select_value("SELECT otp_secret FROM users WHERE id = #{users(:owner).id}")
    assert_not_equal "JBSWY3DPEHPK3PXP", raw
    assert_equal "JBSWY3DPEHPK3PXP", users(:owner).otp_secret
  end

  test "a TOTP code works once only" do
    user = users(:owner)
    code = ROTP::TOTP.new(user.otp_secret).now

    assert user.verify_second_factor(code)
    assert_not user.verify_second_factor(code)
  end

  test "rejects a wrong code" do
    assert_not users(:owner).verify_second_factor("000000")
    assert_not users(:collector).verify_second_factor("000000")
  end

  test "backup codes work once each" do
    user = users(:collector)
    codes = user.enable_two_factor!(User.generate_otp_secret)

    assert_equal User::BACKUP_CODE_COUNT, codes.size
    assert user.verify_second_factor(codes.first)
    assert_not user.verify_second_factor(codes.first)
    assert user.verify_second_factor(codes.second.upcase)
  end

  test "disabling two-step sign-in removes secret and backup codes" do
    user = users(:collector)
    user.enable_two_factor!(User.generate_otp_secret)
    user.disable_two_factor!

    assert_not user.two_factor_enabled?
    assert_nil user.reload.otp_secret
    assert_empty user.otp_backup_codes
  end
end
