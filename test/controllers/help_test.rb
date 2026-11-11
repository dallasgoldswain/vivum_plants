require "test_helper"

class HelpTest < ActionDispatch::IntegrationTest
  setup do
    Flipper.enable("help.manual")
    Flipper.enable("help.contextual")
  end

  test "signed-out visitors can read and search live topics" do
    get help_path
    assert_response :success
    assert_select "a[href=?]", help_topic_path("getting-started")
    assert_select "a[href=?]", help_topic_path("members"), count: 0

    get help_path(q: "backup codes")
    assert_response :success
    assert_select "a[href=?]", help_topic_path("two-step-sign-in")

    get help_topic_path("two-step-sign-in")
    assert_response :success
    assert_select "h1", "Two-step sign-in"
    assert_select "h2#if-you-lose-your-phone"
  end

  test "the manual is hidden while its flag is off" do
    Flipper.disable("help.manual")

    get help_path
    assert_response :not_found
  end

  test "a topic for a capability that's off can't be reached, but can by someone it's on for" do
    get help_topic_path("members")
    assert_response :not_found

    Flipper.enable_actor("seller.workspace", sellers(:fern_and_frond))
    Flipper.enable_actor("seller.members", sellers(:fern_and_frond))
    sign_in_as users(:owner)
    Current.session.update!(seller: sellers(:fern_and_frond))

    get help_topic_path("members")
    assert_response :success
    assert_select "img[src*='help/members-phone']"

    get help_path
    assert_select "a[href=?]", help_topic_path("members")
  end

  test "unknown topics are not found" do
    get help_topic_path("no-such-topic")
    assert_response :not_found
  end

  test "pages show a Help link to their topic when contextual help is on" do
    sign_in_as users(:collector)

    get root_path
    assert_select "a.vv-help-link[href=?]", help_topic_path("getting-started")

    Flipper.disable("help.contextual")
    get root_path
    assert_select "a.vv-help-link", count: 0
  end

  test "What's new shows the release notes and clears the dot once opened" do
    sign_in_as users(:collector)

    get root_path
    assert_select "a[href=?] .vv-dot", whats_new_path

    get whats_new_path
    assert_response :success
    assert_select "h1", "What's new"
    assert_select "h2", "Coming soon"
    assert_not_includes response.body, "Writing rules"
    assert users(:collector).reload.whats_new_seen_at

    get root_path
    assert_select "a[href=?] .vv-dot", whats_new_path, count: 0
  end

  test "What's new is public" do
    get whats_new_path
    assert_response :success
  end
end
