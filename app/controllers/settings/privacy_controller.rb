# Settings → Privacy: every consent, its current state and full history (D57).
class Settings::PrivacyController < ApplicationController
  skip_verify_authorized # acts only on Current.user

  def show
    @current = Current.user.current_consents
    @history = Current.user.consent_records.chronological.reverse
  end
end
