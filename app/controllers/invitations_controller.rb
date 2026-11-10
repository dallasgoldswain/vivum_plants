# The page an invite link opens (D58). Anyone can open it; only the invited email can accept.
class InvitationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: :show
  skip_verify_authorized # the signed token and email match authorise access
  requires_capability "seller.invites"

  before_action :resume_session
  # Signed-in visitors still pass the usual account gates first.
  before_action :require_verified_email, :require_two_factor_enrolment, :require_current_consents, if: -> { Current.user }

  def show
    @invitation = Invitation.find_by_token(params[:token])

    if @invitation.nil? || !@invitation.pending?
      render :unavailable, status: :not_found
    elsif Current.user.nil?
      session[:return_to_after_authenticating] = request.url
      render :sign_in
    elsif !@invitation.for?(Current.user)
      render :wrong_account, status: :forbidden
    end
  end
end
