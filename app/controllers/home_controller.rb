class HomeController < ApplicationController
  skip_verify_authorized

  def show
    @memberships = Current.user.memberships.includes(:seller)
    @invitations = capability?("seller.invites") ? Invitation.pending.for_email(Current.user.email_address).includes(:seller) : Invitation.none
  end
end
