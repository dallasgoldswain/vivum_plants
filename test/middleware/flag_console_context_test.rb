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

  test "a release refused by the guard goes back to the feature page with the reason" do
    console = Rack::Builder.new do
      use FlagConsoleContext
      run ->(_env) { raise FlagReleaseGuard::Refused, "seller.stock has no help topic." }
    end

    with_routing do |set|
      set.draw { mount console, at: "/madmin/flags" }
      post "/madmin/flags/features/seller.stock/boolean", params: { action: "Enable" }

      assert_response :see_other
      assert_equal "/madmin/flags/features/seller.stock?error=seller.stock+has+no+help+topic.", response.location
    end
  end
end
