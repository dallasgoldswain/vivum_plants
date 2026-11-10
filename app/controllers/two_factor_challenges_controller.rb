# Second sign-in step, after a correct password for an account with two-step sign-in on.
class TwoFactorChallengesController < ApplicationController
  layout "auth"
  allow_unauthenticated_access
  skip_verify_authorized
  before_action :require_pending_user
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if (method = @user.verify_second_factor(params[:code]))
      clear_pending_two_factor
      start_new_session_for @user
      Audit.record("session.created", target: @user, details: { second_factor: method })
      redirect_to after_authentication_url
    else
      Audit.record("two_factor.failed", actor: @user, target: @user)
      redirect_to new_two_factor_challenge_path, alert: "That code didn't match."
    end
  end

  private
    def require_pending_user
      @user = pending_two_factor_user
      redirect_to new_session_path, alert: "Please sign in again." unless @user
    end
end
