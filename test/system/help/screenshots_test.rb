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

  test "collection" do
    add_sample_plants
    capture "collection", plants_path, wait_for: "Your plants"
  end

  test "plant" do
    plant = add_sample_plants
    plant.care_events.create!(user: users(:owner), note: "Third leaf hardening off, darker than the last.", occurred_at: 2.days.ago, idempotency_key: "shot")
    capture "plant", plant_path(plant), wait_for: "Add an observation"
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
    def add_sample_plants
      owner = users(:owner)
      owner.plants.create!(display_name: "Anthurium", botanical_name: "Anthurium warocqueanum", growing_context: "terrarium", tag_list: "aroid, velvet")
      owner.plants.create!(display_name: "Java fern", botanical_name: "Microsorum pteropus", cultivar: "Windelov", growing_context: "aquatic", tc_origin: true)
      owner.plants.create!(display_name: "Hoya", botanical_name: "Hoya carnosa", cultivar: "Krimson Queen", growing_context: "indoor",
        acquisition_attributes: { acquired_on: 3.weeks.ago.to_date, source: "Fern & Frond", cost: "185", currency: "ZAR" })
    end

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
