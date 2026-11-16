# Sends a single-use verification link by opening WhatsApp to the buyer's number (D173).
class Sell::Buyers::VerificationsController < Sell::BaseController
  include BuyerScoped
  requires_capability "buyer.phone_verification"

  def create
    verification = BuyerVerification.issue!(@buyer, by: Current.user)
    link = buyer_verification_url(verification.token)
    message = "Hi #{@buyer.name}, #{Current.seller.name} would like to confirm this is your WhatsApp number. Please open #{link}"
    Audit.record("buyer.verification_sent", target: @buyer)
    redirect_to "https://wa.me/#{@buyer.phone.delete_prefix('+')}?text=#{ERB::Util.url_encode(message)}", allow_other_host: true
  end
end
