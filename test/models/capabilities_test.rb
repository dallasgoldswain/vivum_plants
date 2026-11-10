require "test_helper"

class CapabilitiesTest < ActiveSupport::TestCase
  setup do
    Capabilities.registry = Capability::Registry.new(
      "shop.base" => { "domain" => "shop", "state" => "core", "implemented" => true, "description" => "Base" },
      "shop.extra" => { "domain" => "shop", "state" => "core", "implemented" => true, "depends_on" => [ "shop.base" ], "description" => "Needs base" },
      "shop.paid" => { "domain" => "shop", "state" => "pilot", "implemented" => true, "entitlement" => "paid", "description" => "Paid" },
      "shop.later" => { "domain" => "shop", "state" => "core", "description" => "Not built" }
    )
    @seller = sellers(:fern_and_frond)
    @other_seller = sellers(:aroid_attic)
    @user = users(:collector)
  end

  teardown { Capabilities.reset! }

  test "unknown keys deny" do
    Flipper.enable("shop.unknown")
    assert_not Capabilities.enabled?("shop.unknown")
  end

  test "unimplemented keys deny even when enabled in Flipper" do
    Flipper.enable("shop.later")
    assert_not Capabilities.enabled?("shop.later")
  end

  test "off by default" do
    assert_not Capabilities.enabled?("shop.base", user: @user, seller: @seller)
  end

  test "global enable applies to everyone" do
    Flipper.enable("shop.base")
    assert Capabilities.enabled?("shop.base")
    assert Capabilities.enabled?("shop.base", user: @user, seller: @seller)
  end

  test "seller targeting applies to that seller only" do
    Flipper.enable_actor("shop.base", @seller)

    assert Capabilities.enabled?("shop.base", seller: @seller)
    assert Capabilities.enabled?("shop.base", user: @user, seller: @seller)
    assert_not Capabilities.enabled?("shop.base", seller: @other_seller)
    assert_not Capabilities.enabled?("shop.base", user: @user)
  end

  test "user targeting applies to that user only" do
    Flipper.enable_actor("shop.base", @user)

    assert Capabilities.enabled?("shop.base", user: @user)
    assert_not Capabilities.enabled?("shop.base", user: users(:manager))
  end

  test "a disabled dependency denies" do
    Flipper.enable("shop.extra")
    assert_not Capabilities.enabled?("shop.extra")

    Flipper.enable("shop.base")
    assert Capabilities.enabled?("shop.extra")
  end

  test "dependencies are checked for the same actors" do
    Flipper.enable("shop.extra")
    Flipper.enable_actor("shop.base", @seller)

    assert Capabilities.enabled?("shop.extra", seller: @seller)
    assert_not Capabilities.enabled?("shop.extra", seller: @other_seller)
  end

  test "entitlement-gated capabilities deny until billing exists" do
    Flipper.enable("shop.paid")
    assert_not Capabilities.enabled?("shop.paid", seller: @seller)
  end

  test "disabling is an emergency stop that clears every target" do
    Flipper.enable_actor("shop.base", @seller)
    Flipper.disable("shop.base")

    assert_not Capabilities.enabled?("shop.base", seller: @seller)
  end

  test "sync adds every registered key and reports unknown Flipper features" do
    Flipper.add("legacy.flag")

    unknown = Capabilities.sync!(enable_implemented_core: false)

    assert_equal [ "legacy.flag" ], unknown
    assert Flipper.exist?("shop.later")
    assert_not Flipper.enabled?("shop.base")
  end

  test "sync can switch on implemented core capabilities for development" do
    Capabilities.sync!(enable_implemented_core: true)

    assert Flipper.enabled?("shop.base")
    assert_not Flipper.enabled?("shop.paid"), "pilot capabilities stay off"
    assert_not Flipper.enabled?("shop.later"), "unimplemented capabilities stay off"
  end
end
