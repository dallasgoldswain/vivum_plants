# Grants or withdraws an optional consent in one action. Terms and privacy can't be
# withdrawn here; closing the account is the way out (B08).
class Settings::ConsentsController < ApplicationController
  skip_verify_authorized # acts only on Current.user

  def update
    purpose = ConsentRecord::PURPOSES[params[:purpose]]
    return head :not_found if purpose.nil? || purpose.required

    granted = params[:granted] == "1"
    Current.user.record_consent!(purpose.key, granted: granted, source: "settings")
    redirect_back_or_to settings_privacy_path, notice: "#{purpose.label}: #{granted ? "on" : "off"}."
  end
end
