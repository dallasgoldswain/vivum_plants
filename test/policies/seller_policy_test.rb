require "test_helper"

class SellerPolicyTest < ActiveSupport::TestCase
  def policy(membership, seller = sellers(:fern_and_frond))
    SellerPolicy.new(seller, user: membership&.user, membership: membership)
  end

  test "members can view their current seller" do
    assert policy(memberships(:fern_packer)).apply(:show?)
  end

  test "members of another seller cannot view it" do
    assert_not policy(memberships(:attic_owner)).apply(:show?)
  end

  test "only owners can update settings" do
    assert policy(memberships(:fern_owner)).apply(:update?)
    assert_not policy(memberships(:fern_manager)).apply(:update?)
    assert_not policy(memberships(:fern_packer)).apply(:update?)
  end

  test "users can switch only to businesses they belong to" do
    assert policy(memberships(:fern_manager), sellers(:aroid_attic)).apply(:switch_to?)
    assert_not policy(memberships(:fern_packer), sellers(:aroid_attic)).apply(:switch_to?)
  end

  test "collectors without a membership are denied" do
    assert_not SellerPolicy.new(sellers(:fern_and_frond), user: users(:collector), membership: nil).apply(:show?)
  end
end
