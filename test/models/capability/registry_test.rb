require "test_helper"

class Capability::RegistryTest < ActiveSupport::TestCase
  test "the real registry loads and validates" do
    registry = Capability::Registry.load

    assert_operator registry.count, :>=, 100
    assert registry.key?("seller.stock")
    assert_equal "pilot", registry["payments.yoco"].state
    assert_equal %w[ seller.orders buyer.order_link ], registry["payments.yoco"].depends_on
  end

  test "every roadmap capability is unimplemented" do
    Capability::Registry.load.select(&:roadmap?).each do |definition|
      assert_not definition.implemented?, definition.key
    end
  end

  test "rejects unknown dependencies" do
    error = assert_raises(Capability::Registry::Invalid) do
      Capability::Registry.new("a.one" => { "domain" => "a", "state" => "core", "description" => "x", "depends_on" => [ "a.missing" ] })
    end
    assert_match "unknown dependencies a.missing", error.message
  end

  test "rejects dependency cycles" do
    assert_raises(Capability::Registry::Invalid) do
      Capability::Registry.new(
        "a.one" => { "domain" => "a", "state" => "core", "description" => "x", "depends_on" => [ "a.two" ] },
        "a.two" => { "domain" => "a", "state" => "core", "description" => "x", "depends_on" => [ "a.one" ] }
      )
    end
  end

  test "rejects implemented roadmap capabilities and bad states" do
    assert_raises(Capability::Registry::Invalid) do
      Capability::Registry.new("a.one" => { "domain" => "a", "state" => "roadmap", "implemented" => true, "description" => "x" })
    end
    assert_raises(Capability::Registry::Invalid) do
      Capability::Registry.new("a.one" => { "domain" => "a", "state" => "beta", "description" => "x" })
    end
  end

  test "every capability referenced in app code is registered" do
    registry = Capability::Registry.load
    pattern = /(?:requires_capability|capability\?|Capabilities\.enabled\?)\(?\s*["']([a-z_]+\.[a-z_]+)["']/
    referenced = Dir[Rails.root.join("app/**/*.{rb,erb}")].flat_map { |file| File.read(file).scan(pattern).flatten }

    unregistered = referenced.uniq.reject { |key| registry.key?(key) }
    assert_empty unregistered, "Add these keys to config/features.yml"
  end
end
