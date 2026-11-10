require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @operator = users(:collector).tap { it.update!(platform_operator: true) }
    @user = User.create!(email_address: "new-seller@example.com", password: "a-long-password", email_verified_at: Time.current)
  end

  def seller_invite(**attrs)
    Invitation.create!(kind: "seller", role: "owner", email_address: "New-Seller@example.com ", business_name: "Moss & Co", invited_by: @operator, **attrs)
  end

  test "accepting a seller invite creates the business, owner membership and seller terms consent" do
    invitation = seller_invite

    membership = assert_difference -> { Seller.count } => 1, -> { Membership.count } => 1 do
      invitation.accept!(@user, business_name: "Moss and Co", seller_terms: true)
    end

    assert membership.owner?
    assert_equal "Moss and Co", membership.seller.name
    assert @user.consented_to?(:seller_terms)
    assert_equal "accepted", invitation.reload.status
    assert_equal @user, invitation.accepted_by
  end

  test "owners must accept the seller terms" do
    error = assert_raises(Invitation::NotAcceptable) { seller_invite.accept!(@user) }
    assert_match "seller terms", error.message
    assert_equal 0, @user.memberships.count
  end

  test "only the invited email can accept" do
    assert_raises(Invitation::NotAcceptable) { seller_invite.accept!(users(:manager), seller_terms: true) }
  end

  test "expired, revoked and used invites can't be accepted" do
    expired = seller_invite(expires_at: 1.minute.ago)
    assert_raises(Invitation::NotAcceptable) { expired.accept!(@user, seller_terms: true) }

    revoked = seller_invite.tap(&:revoke!)
    assert_raises(Invitation::NotAcceptable) { revoked.accept!(@user, seller_terms: true) }

    used = Invitation.create!(kind: "seller", role: "owner", email_address: @user.email_address, business_name: "Again", invited_by: @operator)
    used.accept!(@user, seller_terms: true)
    assert_raises(Invitation::NotAcceptable) { used.reload.accept!(@user, seller_terms: true) }
  end

  test "resending voids earlier links" do
    invitation = seller_invite
    old_token = invitation.acceptance_token

    travel 1.second do
      invitation.resend!
    end

    assert_nil Invitation.find_by_token(old_token)
    assert_equal invitation, Invitation.find_by_token(invitation.acceptance_token)
  end

  test "a staff invite joins an existing business with its role" do
    invitation = Invitation.create!(kind: "staff", seller: sellers(:fern_and_frond), role: "host_packer", email_address: @user.email_address, invited_by: users(:owner))

    membership = invitation.accept!(@user)
    assert membership.host_packer?
    assert_not @user.consented_to?(:seller_terms)
  end

  test "staff invites reject existing members and duplicates" do
    existing = Invitation.new(kind: "staff", seller: sellers(:fern_and_frond), role: "manager", email_address: users(:packer).email_address, invited_by: users(:owner))
    assert_not existing.valid?

    Invitation.create!(kind: "staff", seller: sellers(:fern_and_frond), role: "manager", email_address: @user.email_address, invited_by: users(:owner))
    duplicate = Invitation.new(kind: "staff", seller: sellers(:fern_and_frond), role: "manager", email_address: @user.email_address, invited_by: users(:owner))
    assert_not duplicate.valid?
  end

  test "seller invites are always for owners" do
    assert_not Invitation.new(kind: "seller", role: "manager", email_address: "x@example.com", business_name: "X", invited_by: @operator).valid?
  end

  test "creating, resending and revoking are audited without the email" do
    invitation = seller_invite
    invitation.resend!
    invitation.revoke!

    assert_equal %w[ invitation.created invitation.resent invitation.revoked ],
      AuditEvent.where(target_type: "Invitation", target_id: invitation.id).order(:id).pluck(:action)
    assert_not AuditEvent.where(target_type: "Invitation", target_id: invitation.id).pluck(:details).to_s.include?("example.com")
  end
end
