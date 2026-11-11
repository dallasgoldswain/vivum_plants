require "application_system_test_case"

# OF02, D84, AT12: an observation saved offline is queued, shown as waiting, and sent once
# when the connection returns. Run with bin/rails test:system (headless Chrome).
class OfflineObservationTest < ApplicationSystemTestCase
  setup do
    %w[ collection.plants collection.media ].each { Flipper.enable(it) }
    users(:collector).update!(whats_new_seen_at: Time.current)
  end

  test "an observation saved offline is sent once when back online" do
    visit new_session_path
    fill_in "Email", with: users(:collector).email_address
    fill_in "Password", with: "password-long-enough"
    click_on "Sign in"
    assert_text "Welcome to VIVUM Plants"

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

  # Chrome's offline emulation doesn't reach service worker fetches, so this checks what the
  # worker saved for offline reading, and that signing out clears it.
  test "opened collection pages are saved for offline reading and cleared at sign-out" do
    visit new_session_path
    fill_in "Email", with: users(:collector).email_address
    fill_in "Password", with: "password-long-enough"
    click_on "Sign in"
    assert_text "Welcome to VIVUM Plants"

    visit plants_path
    assert page.evaluate_async_script("navigator.serviceWorker.ready.then(() => arguments[0](true))")
    visit plants_path
    visit plant_path(plants(:anubias))
    visit new_plant_path
    assert_text "Add a plant"

    cached = page.evaluate_async_script(<<~JS)
      caches.open("vivum-pages-v1").then((cache) => cache.keys()).then((requests) => arguments[0](requests.map((r) => new URL(r.url).pathname)))
    JS
    assert_includes cached, "/plants"
    assert_includes cached, "/plants/#{plants(:anubias).id}"
    assert_not_includes cached, "/plants/new"

    click_on "Sign out", match: :first
    assert_text "Sign in"
    sleep 0.5
    assert_not page.evaluate_async_script("caches.has('vivum-pages-v1').then(arguments[0])")
  end
end
