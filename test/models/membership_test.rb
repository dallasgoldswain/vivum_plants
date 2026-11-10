require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "the last owner can't be removed or demoted" do
    owner = memberships(:fern_owner)

    assert_not owner.destroy
    assert_not owner.update(role: "manager")
    assert_includes owner.errors[:role].first, "at least one owner"
  end

  test "an owner can step down once another owner exists" do
    memberships(:fern_manager).update!(role: "owner")

    assert memberships(:fern_owner).update(role: "manager")
    assert memberships(:fern_owner).destroy
  end

  test "deleting the business removes every membership" do
    assert_difference -> { Membership.count }, -3 do
      sellers(:fern_and_frond).destroy
    end
  end
end
