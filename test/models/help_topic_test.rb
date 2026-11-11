require "test_helper"

class HelpTopicTest < ActiveSupport::TestCase
  setup { HelpTopic.reset! }
  teardown { HelpTopic.reset! }

  test "every topic loads and renders" do
    assert HelpTopic.all.any?
    HelpTopic.all.each { |topic| assert_predicate topic.html, :present?, topic.id }
  end

  # HM02 release check, part one (D76): the build fails while a finished feature has no help.
  test "every implemented user-facing capability has a help topic" do
    missing = Capabilities.registry.select { |definition| definition.implemented? && !definition.internal? }
      .map(&:key).select { |key| HelpTopic.covering(key).empty? }

    assert_empty missing, "Add a topic in app/help covering: #{missing.join(', ')}"
  end

  test "every help link in the views points at a topic and heading that exist" do
    links = Dir[Rails.root.join("app/views/**/*.erb")].flat_map do |path|
      File.read(path).scan(/help_link "([^"]+)"(?:, anchor: "([^"]+)")?/)
    end
    assert links.any?

    links.each do |id, anchor|
      topic = HelpTopic.find(id)
      assert_includes topic.html, %(id="#{anchor}"), "#{id} has no heading ##{anchor}" if anchor
    end
  end

  test "search matches keywords and ranks title matches first" do
    assert_equal "two-step-sign-in", HelpTopic.search("authenticator", user: nil, seller: nil).first&.id
    assert_equal "getting-started", HelpTopic.search("forgot password", user: nil, seller: nil).first&.id
    assert_empty HelpTopic.search("zzzz", user: nil, seller: nil)
    assert_empty HelpTopic.search("  ", user: nil, seller: nil)
  end

  test "a topic shows only when its capabilities are live for the viewer" do
    topic = HelpTopic.find("members")
    owner, seller = users(:owner), sellers(:fern_and_frond)

    assert_not topic.visible_to?(user: owner, seller: seller)
    assert_not_includes HelpTopic.search("roles", user: owner, seller: seller), topic

    Flipper.enable_actor("seller.workspace", seller)
    Flipper.enable_actor("seller.members", seller)
    assert topic.visible_to?(user: owner, seller: seller)
    assert_not topic.visible_to?(user: nil, seller: nil)
    assert_includes HelpTopic.search("roles", user: owner, seller: seller), topic
  end

  test "topics without capabilities always show" do
    assert HelpTopic.find("getting-started").visible_to?(user: nil, seller: nil)
  end

  test "renders screenshots as phone and desktop pictures, and escapes raw HTML" do
    html = HelpTopic::Renderer.render("![The Account page](account)\n\n<script>alert(1)</script>")

    assert_match %r{<source media="\(min-width: 768px\)" srcset="/assets/help/account-desktop-\w+\.png"}, html
    assert_match %r{<img alt="The Account page" loading="lazy" src="/assets/help/account-phone-\w+\.png"}, html
    assert_not_includes html, "<script>"
  end

  test "reviewing stamps the date and digest, and a later edit voids the review" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "privacy.md")
      FileUtils.cp(HelpTopic.find("privacy").path, path)
      File.write(path, File.read(path).gsub(/^reviewed(_digest)?: .*\n/, ""))

      assert_not HelpTopic.load(path).reviewed?

      HelpTopic.load(path).review!(on: Date.new(2026, 11, 11))
      reviewed = HelpTopic.load(path)
      assert reviewed.reviewed?
      assert_equal Date.new(2026, 11, 11), reviewed.reviewed
      assert_equal "privacy", reviewed.id

      File.write(path, File.read(path) + "\nOne more line.\n")
      assert_not HelpTopic.load(path).reviewed?
    end
  end

  test "a topic must name a known capability and audience" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "broken.md")
      File.write(path, "---\nid: broken\ntitle: Broken\naudience: everyone\ncapabilities: [nope.never]\n---\nText\n")
      assert_raises(HelpTopic::Invalid) { HelpTopic.load(path) }

      File.write(path, "---\nid: broken\ntitle: Broken\naudience: martians\n---\nText\n")
      assert_raises(HelpTopic::Invalid) { HelpTopic.load(path) }
    end
  end
end
