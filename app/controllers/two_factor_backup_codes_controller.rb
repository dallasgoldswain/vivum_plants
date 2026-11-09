# Replaces the signed-in user's backup codes. Needs a current code.
class TwoFactorBackupCodesController < ApplicationController
  skip_verify_authorized # acts only on Current.user
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to root_path, alert: "Try again later." }

  def create
    if Current.user.verify_second_factor(params[:code])
      @backup_codes = Current.user.regenerate_backup_codes!
    else
      redirect_to root_path, alert: "That code didn't match."
    end
  end
end
