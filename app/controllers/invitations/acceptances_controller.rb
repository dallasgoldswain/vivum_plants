# Accepts an invite for the signed-in account: creates the business for seller invites, then
# the membership, and switches the session to act for that business.
class Invitations::AcceptancesController < ApplicationController
  skip_verify_authorized # Invitation#accept! checks the token's invite is pending and for this account
  requires_capability "seller.invites"

  def create
    invitation = Invitation.find_by_token(params[:invitation_token])
    return redirect_to(root_path, alert: "That invite is no longer valid.") unless invitation

    membership = invitation.accept!(Current.user, business_name: params[:business_name], seller_terms: params[:seller_terms] == "1")
    Current.session.update!(seller: membership.seller)
    redirect_to sell_root_path, notice: "Welcome to #{membership.seller.name}."
  rescue Invitation::NotAcceptable => error
    redirect_to invitation_path(params[:invitation_token]), alert: error.message
  end
end
