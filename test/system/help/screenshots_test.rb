require "application_system_test_case"

# Screenshots for help topics (D78), saved as app/assets/images/help/<name>-phone.png and
# -desktop.png. Not part of CI: run bin/rails help:screenshots after a page changes, check
# the images, and commit them with the topic.
class HelpScreenshotsTest < ApplicationSystemTestCase
  DIRECTORY = Rails.root.join("app/assets/images/help")
  SIZES = {
    phone: { width: 390, height: 844, deviceScaleFactor: 2, mobile: true },
    desktop: { width: 1280, height: 860, deviceScaleFactor: 1, mobile: false }
  }.freeze

  setup do
    Capabilities.registry.select(&:implemented?).each { |definition| Flipper.enable(definition.key) }
    users(:owner).update!(whats_new_seen_at: Time.current)
    sign_in_as_owner
  end

  test "privacy" do
    capture "privacy", settings_privacy_path, wait_for: "Your choices"
  end

  test "account" do
    capture "account", settings_account_path, wait_for: "Export your data"
  end

  test "sell home" do
    capture "sell-home", sell_root_path, wait_for: "Plan"
  end

  test "members" do
    capture "members", sell_members_path, wait_for: "Team"
  end

  private
    def sign_in_as_owner
      visit new_session_path
      fill_in "Email", with: users(:owner).email_address
      fill_in "Password", with: "password-long-enough"
      click_on "Sign in"
      fill_in "code", with: ROTP::TOTP.new(users(:owner).otp_secret).now
      click_on "Verify"
      assert_text "Welcome to VIVUM Plants"
    end

    def capture(name, path, wait_for:)
      SIZES.each do |size, metrics|
        page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", **metrics)
        visit path
        assert_text wait_for
        page.driver.browser.save_screenshot(DIRECTORY.join("#{name}-#{size}.png").to_s)
      end
    ensure
      page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    end
end
