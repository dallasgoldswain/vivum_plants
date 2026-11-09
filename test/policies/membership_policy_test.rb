require "test_helper"

class MembershipPolicyTest < ActiveSupport::TestCase
  def policy(membership, record)
    MembershipPolicy.new(record, user: membership.user, membership: membership)
  end

  test "owners manage members of their own seller" do
    owner = memberships(:fern_owner)
    assert policy(owner, Membership).apply(:create?)
    assert policy(owner, memberships(:fern_packer)).apply(:update?)
    assert policy(owner, memberships(:fern_packer)).apply(:destroy?)
  end

  test "owners cannot remove themselves" do
    owner = memberships(:fern_owner)
    assert_not policy(owner, owner).apply(:destroy?)
  end

  test "managers and packers cannot manage members" do
    [ memberships(:fern_manager), memberships(:fern_packer) ].each do |membership|
      assert_not policy(membership, Membership).apply(:create?)
      assert_not policy(membership, memberships(:fern_owner)).apply(:update?)
      assert_not policy(membership, memberships(:fern_owner)).apply(:destroy?)
    end
  end

  test "owners cannot touch another seller's members" do
    assert_not policy(memberships(:attic_owner), memberships(:fern_packer)).apply(:destroy?)
    assert_not policy(memberships(:attic_owner), memberships(:fern_packer)).apply(:show?)
  end

  test "scope only returns members of the current seller" do
    scoped = MembershipPolicy.new(Membership, user: users(:packer), membership: memberships(:fern_packer))
      .apply_scope(Membership.all, type: :active_record_relation)

    assert_equal sellers(:fern_and_frond).memberships.sort, scoped.sort
  end

  test "scope is empty without a current seller" do
    scoped = MembershipPolicy.new(Membership, user: users(:collector), membership: nil)
      .apply_scope(Membership.all, type: :active_record_relation)

    assert_empty scoped
  end
end
