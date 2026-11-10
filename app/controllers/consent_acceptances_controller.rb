# Asks signed-in users to accept the current terms and privacy notice: accounts created
# before consents existed, and everyone after a new version is published (D56).
class ConsentAcceptancesController < ApplicationController
  layout "auth"
  allow_without_current_consents
  skip_verify_authorized # acts only on Current.user

  before_action -> { redirect_to root_path if Current.user.required_consents_accepted? }

  def new
    @pending = Current.user.pending_required_consents.map { ConsentRecord.purpose(it) }
  end

  def create
    if params[:accept] == "1"
      Current.user.accept_required_consents!(source: "re_acceptance")
      redirect_to session.delete(:return_to_after_consenting) || root_path, notice: "Thanks, you're all set."
    else
      redirect_to new_consent_acceptance_path, alert: "Tick the box to accept and continue."
    end
  end
end
