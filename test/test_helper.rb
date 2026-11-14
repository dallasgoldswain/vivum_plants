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

    # On macOS, libvips draws text through CoreText, which crashes inside forked test
    # workers. There, sale cards draw a block the size the text would take instead, so the
    # layout and fitting still run; CI on Linux renders real text.
    if RUBY_PLATFORM.include?("darwin")
      parallelize_setup do |_worker|
        SaleCard::Renderer.prepend(Module.new do
          def text(markup, size, width, color = nil)
            characters = markup.gsub(/<[^>]+>/, "").length
            lines = [ (characters * size * 0.55 / width).ceil, 1 ].max
            Vips::Image.black([ characters * size * 0.55, width ].min.ceil.clamp(1, width), (lines * size * 1.2).ceil, bands: 4).copy(interpretation: :srgb)
          end
        end)
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
