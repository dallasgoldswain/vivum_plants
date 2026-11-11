require "test_helper"

class EntitlementsTest < ActiveSupport::TestCase
  setup do
    Capabilities.registry = Capability::Registry.new(
      "brand.base" => { "domain" => "brand", "state" => "core", "implemented" => true, "description" => "Base" },
      "brand.paid" => { "domain" => "brand", "state" => "pilot", "implemented" => true, "entitlement" => "paid_branding", "depends_on" => [ "brand.base" ], "description" => "Paid" }
    )
    %w[ brand.base brand.paid ].each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
  end

  teardown { Capabilities.reset! }

  test "a comp seller on Pro gets paid branding without any payment record" do
    @seller.update!(billing_mode: "comp", audit_reason: "Friend of VIVUM")
    assert Capabilities.enabled?("brand.paid", seller: @seller)
  end

  test "a Starter seller doesn't, even with the flag on" do
    @seller.update!(plan: plans(:starter), audit_reason: "Testing")
    assert Flipper.enabled?("brand.paid")
    assert_not Capabilities.enabled?("brand.paid", seller: @seller)
  end

  test "an entitlement needs a seller" do
    assert_not Capabilities.enabled?("brand.paid", user: users(:collector))
    assert Capabilities.enabled?("brand.base", user: users(:collector))
  end
end
