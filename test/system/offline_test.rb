require "application_system_test_case"

# OF02, D84, D94, D102, AT12: observations and readings saved offline are queued, shown as
# waiting, and sent once when the connection returns. Run in headless Chrome (bin/ci).
class OfflineTest < ApplicationSystemTestCase
  setup do
    %w[ collection.plants collection.media collection.environments collection.measurements substrate.ingredients substrate.recipes substrate.scaling care.logs care.reminders ].each { Flipper.enable(it) }
    users(:collector).update!(whats_new_seen_at: Time.current)
  end

  # A failed test must not leave the browser offline for the next one.
  teardown do
    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 0 }
  end

  test "an observation saved offline is sent once when back online" do
    sign_in

    visit plant_path(plants(:anubias))
    assert_text "Add an observation"

    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
    fill_in "Note", with: "Pearling under the new light"
    click_on "Save observation"
    assert_text "Saved on this device"
    assert_text "Waiting to send"
    assert_equal 0, CareEvent.count

    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 0 }
    page.execute_script("window.dispatchEvent(new Event('online'))")
    assert_text "Pearling under the new light", wait: 10
    assert_no_text "Waiting to send"

    page.execute_script("window.dispatchEvent(new Event('online'))")
    sleep 1
    assert_equal 1, CareEvent.where(note: "Pearling under the new light").count
  end

  test "a watering tapped offline and a feeding saved offline are sent once (D103, D110)" do
    sign_in
    visit plant_path(plants(:anubias))
    assert_text "Log care"

    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
    click_on "Water"
    assert_text "Saved on this device"
    within("#care") { click_on "Feed" }
    within("#care-feeding") do
      fill_in "Fertiliser", with: "Seaweed feed"
      click_on "Save"
    end
    assert_no_selector "#care-feeding[open]"
    assert_text "Fed · Seaweed feed"
    assert_equal 0, CareEvent.count

    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 0 }
    page.execute_script("window.dispatchEvent(new Event('online'))")
    assert_no_text "Waiting to send", wait: 10
    page.execute_script("window.dispatchEvent(new Event('online'))")
    sleep 1
    assert_equal [ "feeding", "watering" ], CareEvent.order(:kind).pluck(:kind)
    assert_equal "Seaweed feed", CareEvent.feeding.sole.product
  end

  test "Water saves at once online, and Undo removes it" do
    sign_in
    visit plant_path(plants(:anubias))
    click_on "Water"
    assert_text "Add details"
    assert_equal 1, CareEvent.watering.count
    click_on "Undo"
    assert_text "Entry deleted."
    assert_equal 0, CareEvent.count
  end

  test "Done on Today saved offline is sent once, logging care for each ticked plant (D120)" do
    user = users(:collector)
    tasks = [ plants(:anubias), plants(:monstera_one) ].map do |plant|
      user.care_schedules.create!(plant: plant, kind: "watering", interval: 7, interval_unit: "day", starts_on: Date.current).tap(&:start!).open_task
    end
    sign_in
    visit root_path
    assert_text "Water · 2 plants"

    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
    uncheck "task_due_#{tasks.last.id}"
    click_on "Done for ticked plants"
    assert_text "Saved on this device"
    assert_text "Water done"
    assert_equal 0, CareEvent.count

    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 0 }
    page.execute_script("window.dispatchEvent(new Event('online'))")
    assert_no_text "Waiting to send", wait: 10
    page.execute_script("window.dispatchEvent(new Event('online'))")
    sleep 1
    assert_equal [ plants(:anubias) ], CareEvent.watering.map(&:plant)
    assert tasks.first.reload.completed?
    assert tasks.last.reload.open?
  end

  test "the reminder form previews the next dates as you choose" do
    sign_in
    visit new_plant_care_schedule_path(plants(:anubias))
    fill_in "First date", with: Date.new(2027, 1, 31)
    find_field("care_schedule_interval").fill_in(with: "1")
    find("select[name='care_schedule[interval_unit]']").select("months")
    choose "Fixed dates (every Monday, or the 1st of the month)"
    assert_text "Sun 31 Jan · Sun 28 Feb · Wed 31 Mar · Fri 30 Apr · Mon 31 May"
    choose "Once"
    assert_text "Sun 31 Jan"
    assert_no_text "28 Feb"
  end

  test "a reading saved offline is sent once when back online" do
    sign_in
    visit environment_path(environments(:tank))
    assert_text "Conditions"

    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
    fill_in "pH", with: "6.8"
    click_on "Save reading"
    assert_text "Saved on this device"
    assert_text "Waiting to send"
    assert_text "pH 6.8"
    assert_equal 0, Measurement.count

    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 0 }
    page.execute_script("window.dispatchEvent(new Event('online'))")
    assert_no_text "Waiting to send", wait: 10
    assert_selector "#conditions dd", text: "6.8"

    page.execute_script("window.dispatchEvent(new Event('online'))")
    sleep 1
    assert_equal 1, Measurement.count
    assert_equal BigDecimal("6.8"), MeasurementValue.sole.value
  end

  # Chrome's offline emulation doesn't reach service worker fetches, so this checks what the
  # worker saved for offline reading, and that signing out clears it.
  test "opened collection pages are saved for offline reading and cleared at sign-out" do
    sign_in

    visit plants_path
    assert page.evaluate_async_script("navigator.serviceWorker.ready.then(() => arguments[0](true))")
    visit plants_path
    visit plant_path(plants(:anubias))
    visit environment_path(environments(:shelf))
    visit recipe_path(recipes(:aroid_mix))
    visit ingredient_path(ingredients(:bark))
    visit new_plant_path
    assert_text "Add a plant"

    cached = page.evaluate_async_script(<<~JS)
      caches.open("vivum-pages-v1").then((cache) => cache.keys()).then((requests) => arguments[0](requests.map((r) => new URL(r.url).pathname)))
    JS
    assert_includes cached, "/plants"
    assert_includes cached, "/plants/#{plants(:anubias).id}"
    assert_includes cached, "/environments/#{environments(:shelf).id}"
    assert_includes cached, "/recipes/#{recipes(:aroid_mix).id}"
    assert_includes cached, "/ingredients/#{ingredients(:bark).id}"
    assert_not_includes cached, "/plants/new"

    click_on "Sign out", match: :first
    assert_text "Sign in"
    sleep 0.5
    assert_not page.evaluate_async_script("caches.has('vivum-pages-v1').then(arguments[0])")
  end

  test "scaling a recipe works offline" do
    sign_in
    visit recipe_path(recipes(:aroid_mix))
    assert_text "Make a batch"

    page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
    fill_in "Total", with: "4"
    within("#scale") do
      assert_equal [ "2 L", "1 L", "1 L" ], all("[data-scale-target=volume]").map(&:text)
      assert_text "Total after rounding 4 L"
    end

    select "mL", from: "Unit"
    fill_in "Total", with: "500"
    within("#scale") { assert_equal [ "250 mL", "125 mL", "125 mL" ], all("[data-scale-target=volume]").map(&:text) }
  ensure
    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 0 }
  end

  test "the recipe form adds ingredient rows and shows the running total" do
    sign_in
    visit new_recipe_path
    fill_in "Name", with: "Gritty mix"
    choose "Percent"
    select "Perlite", from: "version_components_0_ingredient_id"
    fill_in "version_components_0_quantity", with: "60"
    assert_text "Total: 60% (needs to be 100% to mark ready)"

    click_on "Add an ingredient"
    assert_selector "[data-recipe-rows-row]", count: 4
    rows = all("[data-recipe-rows-row]")
    rows.last.find("select").select("Orchid bark, medium")
    rows.last.find("input").fill_in(with: "40")
    assert_text "Total: 100%"

    click_on "Save, ready to use"
    assert_text "Gritty mix saved."
    assert_equal [ 60, 40 ], Recipe.find_by!(name: "Gritty mix").current_version.components.map { it.quantity.to_i }
  end

  private
    def sign_in
      visit new_session_path
      fill_in "Email", with: users(:collector).email_address
      fill_in "Password", with: "password-long-enough"
      click_on "Sign in"
      assert_text "Signed in as"
    end
end
