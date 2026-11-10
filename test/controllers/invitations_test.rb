require "test_helper"

class InvitationsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    %w[ seller.workspace seller.members seller.invites ].each { Flipper.enable(it) }
    @collector = users(:collector)
  end

  def staff_invite(email: @collector.email_address, role: "manager")
    Invitation.create!(kind: "staff", seller: sellers(:fern_and_frond), role: role, email_address: email, invited_by: users(:owner))
  end

  test "an uninvited account can't open Sell" do
    sign_in_as @collector
    get sell_root_path
    assert_response :not_found
  end

  test "Sell is hidden when the workspace flag is off" do
    Flipper.disable("seller.workspace")
    sign_in_as users(:owner)
    get sell_root_path
    assert_response :not_found
  end

  test "an operator issues a seller invite in Madmin and an email goes out" do
    operator = users(:owner).tap { it.update!(platform_operator: true) }
    sign_in_as operator

    assert_enqueued_emails 1 do
      post madmin_invitations_path, params: { invitation: { email_address: "grower@example.com", business_name: "Grower Co" } }
    end

    invitation = Invitation.last
    assert invitation.seller? && invitation.role_owner?
    assert_equal operator, invitation.invited_by

    post revoke_madmin_invitation_path(invitation)
    assert_equal "revoked", invitation.reload.status
  end

  test "opening an invite signed out asks you to sign in and returns to it" do
    token = staff_invite.acceptance_token

    get invitation_path(token)
    assert_response :success
    assert_match "Fern &amp; Frond", response.body

    post session_path, params: { email_address: @collector.email_address, password: "password-long-enough" }
    assert_redirected_to invitation_url(token)
  end

  test "accepting a staff invite joins the business and opens Sell" do
    invitation = staff_invite
    sign_in_as @collector

    get invitation_path(invitation.acceptance_token)
    assert_response :success

    post invitation_acceptance_path(invitation.acceptance_token)
    assert_redirected_to sell_root_path
    follow_redirect!
    assert_response :success
    assert @collector.memberships.manager.exists?(seller: sellers(:fern_and_frond))
  end

  test "accepting a seller invite makes you an owner, who then sets up two-step sign-in" do
    invitation = Invitation.create!(kind: "seller", role: "owner", email_address: @collector.email_address, business_name: "Moss & Co", invited_by: users(:owner))
    sign_in_as @collector

    post invitation_acceptance_path(invitation.acceptance_token), params: { business_name: "Moss & Co" }
    assert_redirected_to invitation_path(invitation.acceptance_token), "seller terms are required"

    post invitation_acceptance_path(invitation.acceptance_token), params: { business_name: "Moss & Co", seller_terms: "1" }
    assert_redirected_to sell_root_path

    get sell_root_path
    assert_redirected_to new_two_factor_enrolment_path
  end

  test "an invite for another email can't be used" do
    invitation = staff_invite(email: "someone-else@example.com")
    sign_in_as @collector

    get invitation_path(invitation.acceptance_token)
    assert_response :forbidden

    post invitation_acceptance_path(invitation.acceptance_token)
    assert_not @collector.memberships.exists?
  end

  test "an expired invite shows as unavailable" do
    invitation = staff_invite
    invitation.update_columns(expires_at: 1.minute.ago)

    get invitation_path(invitation.acceptance_token)
    assert_response :not_found
  end

  test "pending invites show on the home page" do
    staff_invite
    sign_in_as @collector

    get root_path
    assert_select "a", text: "View invite"
  end

  test "owners invite, resend and cancel staff invites" do
    sign_in_as users(:owner)

    assert_enqueued_emails 1 do
      post sell_invitations_path, params: { invitation: { email_address: "helper@example.com", role: "host_packer" } }
    end
    invitation = Invitation.find_by!(email_address: "helper@example.com")
    assert invitation.role_host_packer?

    get sell_members_path
    assert_select "input[value=?]", invitation_url(invitation.acceptance_token)

    assert_enqueued_emails(1) { post resend_sell_invitation_path(invitation) }
    delete sell_invitation_path(invitation)
    assert_equal "revoked", invitation.reload.status
  end

  test "managers and packers can't manage members" do
    sign_in_as users(:packer)

    get sell_members_path
    assert_response :success
    assert_select "form[action=?]", sell_invitations_path, count: 0

    post sell_invitations_path, params: { invitation: { email_address: "x@example.com", role: "owner" } }
    assert_not Invitation.exists?(email_address: "x@example.com")

    patch sell_member_path(memberships(:fern_packer)), params: { membership: { role: "owner" } }
    assert memberships(:fern_packer).reload.host_packer?
  end

  test "owners change roles and remove members, who lose access at once" do
    sign_in_as users(:owner)
    patch sell_member_path(memberships(:fern_manager)), params: { membership: { role: "host_packer" } }
    assert memberships(:fern_manager).reload.host_packer?

    delete sell_member_path(memberships(:fern_packer))
    assert_not Membership.exists?(memberships(:fern_packer).id)
    assert_equal "membership.removed", AuditEvent.order(:id).last.action

    sign_in_as users(:packer)
    get sell_root_path
    assert_response :not_found
  end

  test "the last owner can't be removed or demoted" do
    sign_in_as users(:owner)

    delete sell_member_path(memberships(:fern_owner))
    assert Membership.exists?(memberships(:fern_owner).id)

    patch sell_member_path(memberships(:fern_owner)), params: { membership: { role: "manager" } }
    assert memberships(:fern_owner).reload.owner?
  end

  test "owners are asked to accept a new seller terms version" do
    users(:owner).consent_records.where(purpose: "seller_terms").delete_all
    sign_in_as users(:owner)

    get sell_root_path
    assert_redirected_to new_consent_acceptance_path
  end
end
