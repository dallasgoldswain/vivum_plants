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
    plant.care_events.create!(user: users(:owner), kind: "watering", amount: 300, amount_unit: "mL", watering_method: "bottom", occurred_at: 1.day.ago, idempotency_key: "shot-water")
    plant.care_events.create!(user: users(:owner), kind: "feeding", product: "Seaweed feed", amount: 2, amount_unit: "mL/L", strength: "half", occurred_at: 9.days.ago, idempotency_key: "shot-feed")
    capture "plant", plant_path(plant), wait_for: "Add an observation"
  end

  test "today" do
    owner = users(:owner)
    add_sample_plants
    anthurium, java_fern, hoya = %w[ Anthurium Java\ fern Hoya ].map { owner.plants.find_by!(display_name: it) }
    [ [ anthurium, 3 ], [ hoya, 0 ] ].each do |plant, days_ago|
      owner.care_schedules.create!(plant: plant, kind: "watering", interval: 7, interval_unit: "day", starts_on: days_ago.days.ago.to_date).start!
    end
    owner.care_schedules.create!(plant: hoya, kind: "feeding", interval: 2, interval_unit: "week", mode: "fixed", starts_on: Date.current, note: "Half-strength").start!
    owner.care_schedules.create!(plant: java_fern, kind: "custom", label: "Trim old leaves", interval: 1, interval_unit: "month", starts_on: 4.days.from_now.to_date).start!
    capture "today", root_path, wait_for: "Due now"
  end

  test "environment" do
    owner = users(:owner)
    hoya = add_sample_plants
    tank = owner.environments.create!(name: "60 cm planted tank", kind: "aquarium", length_cm: 60, width_cm: 30, height_cm: 36, volume_litres: 54)
    owner.plants.find_by!(display_name: "Java fern").move_to!(tank, on: 3.weeks.ago.to_date)
    reading = owner.measurements.new(environment: tank, measured_at: 1.day.ago, source: "API test kit", idempotency_key: "shot")
    reading.assign_readings(fixed: { "water_temperature" => "24.5", "ph" => "6.8", "gh" => "6", "kh" => "4", "light_hours" => "7" })
    reading.save!
    hoya.move_to!(tank)
    owner.environment_events.create!(environment: tank, kind: "water_change", amount: 30, amount_unit: "%", occurred_at: 2.days.ago, idempotency_key: "shot-wc")
    owner.environment_events.create!(environment: tank, kind: "dosing", product: "Liquid fertiliser", amount: 5, amount_unit: "mL", occurred_at: 2.days.ago, idempotency_key: "shot-dose")
    owner.care_schedules.create!(environment: tank, kind: "water_change", interval: 1, interval_unit: "week", mode: "fixed", starts_on: 5.days.from_now.to_date, note: "25–30%").start!
    capture "environment", environment_path(tank), wait_for: "Conditions"
  end

  test "recipe" do
    owner = users(:owner)
    Ingredient.sync_built_ins!
    bark, perlite, coir = %w[ orchid_bark_medium perlite coco_coir ].map { Ingredient.find_by!(key: it) }
    recipe = owner.recipes.new(name: "Chunky aroid mix", contexts: %w[ indoor terrarium ], source: "My own")
    rows = [ [ bark, 2 ], [ perlite, 1 ], [ coir, 1 ] ].map { |ingredient, quantity| { ingredient_id: ingredient.id, quantity: quantity } }
    recipe.save_revision(recipe.build_revision(basis: "parts", notes: "Soak the bark overnight and mix damp.", ready: true, components: rows))
    add_sample_plants.change_setup!({ container: "Clear nursery pot", recipe_version_id: recipe.current_version.id }, on: 2.weeks.ago.to_date)
    capture "recipe", recipe_path(recipe), wait_for: "Make a batch"
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
      assert_text "Signed in as"
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
