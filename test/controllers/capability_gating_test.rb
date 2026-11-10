require "test_helper"

class CapabilityGatingTest < ActionDispatch::IntegrationTest
  class GatedController < ApplicationController
    skip_verify_authorized
    requires_capability "shop.base"

    def show
      render plain: "gated content"
    end
  end

  setup do
    Capabilities.registry = Capability::Registry.new(
      "shop.base" => { "domain" => "shop", "state" => "core", "implemented" => true, "description" => "Base" }
    )
  end

  teardown { Capabilities.reset! }

  test "a disabled capability's URL returns 404" do
    with_gated_route do
      get "/gated"
      assert_response :not_found
    end
  end

  test "an enabled capability's URL works" do
    Flipper.enable_actor("shop.base", sellers(:fern_and_frond))

    with_gated_route do
      get "/gated"
      assert_response :success
      assert_equal "gated content", response.body
    end
  end

  private
    def with_gated_route(&)
      with_routing do |set|
        set.draw do
          resource :session
          get "/gated", to: "capability_gating_test/gated#show"
        end
        sign_in_as users(:packer)
        yield
      end
    end
end
