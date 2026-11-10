require "test_helper"

class FlagConsoleContextTest < ActionDispatch::IntegrationTest
  test "flag changes made inside the console are attributed to the signed-in operator" do
    probe = Rack::Builder.new do
      use FlagConsoleContext
      run ->(_env) { Flipper.enable("seller.stock"); [ 200, {}, [ "ok" ] ] }
    end

    with_routing do |set|
      set.draw do
        resource :session
        mount probe, at: "/probe"
      end
      sign_in_as users(:owner)
      get "/probe"
    end

    event = AuditEvent.find_by!(action: "flag.enable", target_key: "seller.stock")
    assert_equal users(:owner), event.actor
    assert_equal({ "gate" => "boolean", "value" => true }, event.details)
  end
end
