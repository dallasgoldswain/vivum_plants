class EmailVerificationsController < ApplicationController
  layout "auth"
  allow_unauthenticated_access only: :show
  allow_unverified_email_access only: %i[ new create ]
  skip_verify_authorized
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_email_verification_path, alert: "Try again later." }

  # "Check your email" page, with a resend button.
  def new
    redirect_to root_path if Current.user.email_verified?
  end

  def create
    EmailVerificationMailer.verify(Current.user).deliver_later unless Current.user.email_verified?
    redirect_to new_email_verification_path, notice: "We sent a new verification link."
  end

  def show
    if user = User.find_by_token_for(:email_verification, params[:token])
      user.verify_email!
      redirect_to(authenticated? ? root_path : new_session_path, notice: "Your email address is verified.")
    else
      redirect_to new_session_path, alert: "That verification link is invalid or has expired."
    end
  end
end
