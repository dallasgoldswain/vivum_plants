require "test_helper"

# HM02 release check, part two (D76): production refuses to release a capability to
# everyone until its help topic is reviewed.
class FlagReleaseGuardTest < ActiveSupport::TestCase
  setup do
    entries = YAML.safe_load_file(Rails.root.join("config/features.yml")).merge(
      "shop.unhelped" => { "domain" => "shop", "state" => "core", "implemented" => true, "description" => "No topic" },
      "shop.tooling" => { "domain" => "shop", "state" => "core", "implemented" => true, "internal" => true, "description" => "Operator tool" }
    )
    Capabilities.registry = Capability::Registry.new(entries)
    HelpTopic.reset!
    @flipper = Flipper.new(FlagReleaseGuard.new(Flipper::Adapters::Memory.new))
  end

  teardown do
    Capabilities.reset!
    HelpTopic.reset!
  end

  test "enabling for everyone or a percentage is refused without a topic" do
    error = assert_raises(FlagReleaseGuard::Refused) { @flipper.enable("shop.unhelped") }
    assert_match "has no help topic", error.message
    assert_raises(FlagReleaseGuard::Refused) { @flipper.enable_percentage_of_actors("shop.unhelped", 10) }
    assert_raises(FlagReleaseGuard::Refused) { @flipper.enable_percentage_of_time("shop.unhelped", 10) }
    assert_not @flipper.enabled?("shop.unhelped")
  end

  test "enabling for one user or seller, and turning off, always work" do
    @flipper.enable_actor("shop.unhelped", users(:owner))
    @flipper.enable_actor("shop.unhelped", sellers(:fern_and_frond))
    assert @flipper.enabled?("shop.unhelped", users(:owner))

    @flipper.disable("shop.unhelped")
    @flipper.enable_percentage_of_actors("shop.unhelped", 0)
    assert_not @flipper.enabled?("shop.unhelped", users(:owner))
  end

  test "an unreviewed or edited topic blocks the release; a reviewed one allows it" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "privacy.md")
      File.write(path, File.read(HelpTopic.find("privacy").path).gsub(/^reviewed(_digest)?: .*\n/, ""))
      HelpTopic.directory = dir

      error = assert_raises(FlagReleaseGuard::Refused) { @flipper.enable("privacy.dsr") }
      assert_match "help:review[privacy]", error.message

      HelpTopic.find("privacy").review!
      @flipper.enable("privacy.dsr")
      assert @flipper.enabled?("privacy.dsr")

      @flipper.disable("privacy.dsr")
      File.write(path, File.read(path) + "\nAn edit after the review.\n")
      HelpTopic.reset!
      assert_raises(FlagReleaseGuard::Refused) { @flipper.enable("privacy.dsr") }
    ensure
      HelpTopic.directory = nil
    end
  end

  test "internal and unimplemented capabilities have nothing to check" do
    @flipper.enable("shop.tooling")
    @flipper.enable("seller.packing")
    assert @flipper.enabled?("shop.tooling")
  end
end
