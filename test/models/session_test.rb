require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "defaults to the user's only membership" do
    session = users(:packer).sessions.create!
    assert_equal memberships(:fern_packer), session.membership
  end

  test "has no membership by default when the user belongs to several sellers" do
    assert_nil users(:manager).sessions.create!.membership
  end

  test "removing a member revokes access on the next lookup" do
    session = users(:packer).sessions.create!(seller: sellers(:fern_and_frond))
    memberships(:fern_packer).destroy

    assert_nil session.membership
  end
end
