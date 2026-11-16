# A buyer confirms their number from the link the seller sent (BY03, D173), and can give or
# withdraw consent to that seller (D174). Opens without signing in, names the seller as the
# responsible party (PR02) and shows only a masked number.
class BuyerVerificationsController < ApplicationController
  allow_unauthenticated_access
  skip_verify_authorized
  layout "public"
  before_action :set_verification

  def show
    @confirmed = flash[:verified]
  end

  def update
    return render(:show, status: :gone) unless @verification.confirm!

    BuyerConsent::PURPOSES.each_key do |purpose|
      granted = params.dig(:consents, purpose) == "1"
      @buyer.record_consent!(purpose, granted: granted, source: "buyer", method: "Verification page") unless granted == @buyer.consent?(purpose)
    end
    redirect_to buyer_verification_path(params[:token]), flash: { verified: true }
  end

  private
    def set_verification
      @verification = BuyerVerification.find_by_token(params[:token])
      raise ActiveRecord::RecordNotFound unless @verification && Capabilities.enabled?("buyer.phone_verification", seller: @verification.buyer.seller)

      @buyer = @verification.buyer
      @seller = @buyer.seller
      response.headers["X-Robots-Tag"] = "noindex, nofollow"
      response.headers["Referrer-Policy"] = "no-referrer"
      response.headers["Cache-Control"] = "no-store"
    end
end
