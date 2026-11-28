require "test_helper"

# Capybara 3.40 resets Chrome with Storage.clearDataForOrigin for origin "*", which newer
# Chrome rejects ("* is not a valid URL"). Clear the app server's origin instead.
module ChromeResetOrigin
  private
    def execute_cdp(cmd, params = {})
      params = params.merge(origin: Capybara.current_session.server.base_url) if cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"
      super
    end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeResetOrigin)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ], options: {
      browser: :remote,
      url: "http://#{ENV["SELENIUM_HOST"]}:4444"
    }
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
