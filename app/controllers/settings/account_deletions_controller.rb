# Deleting an account (PR07, D69–D71, D73). Asks for the password, and the two-step code when
# it's on, so a borrowed or stolen session can't do it.
class Settings::AccountDeletionsController < ApplicationController
  skip_verify_authorized # acts only on Current.user
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_settings_account_deletion_path, alert: "Try again later." }

  def new
    @sole_owned_sellers = Current.user.sole_owned_sellers.to_a
  end

  def create
    user = Current.user
    unless user.authenticate_password(params[:password].to_s) && (!user.two_factor_enabled? || user.verify_second_factor(params[:code]))
      Audit.record("account.deletion_reauth_failed", target: user)
      return redirect_to new_settings_account_deletion_path, alert: "That password or code didn't match."
    end

    user.request_deletion!
    cookies.delete(:session_id)
    redirect_to new_session_path, notice: "Your account is switched off and will be deleted on #{l user.deletion_due_on, format: :long}. Sign in before then to keep it."
  rescue User::NotDeletable => error
    redirect_to new_settings_account_deletion_path, alert: error.message
  end
end
