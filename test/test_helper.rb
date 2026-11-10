ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# Flipper's test helper builds its instance without instrumentation; restore it so flag
# changes reach the audit log subscriber (config/initializers/flipper.rb).
Flipper.configure do |config|
  config.default { Flipper.new(config.adapter, instrumenter: ActiveSupport::Notifications) }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
