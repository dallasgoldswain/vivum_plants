# Loads a buyer of the business the session acts for; another seller's buyer is a 404.
module BuyerScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "seller.buyers"
    before_action :set_buyer
  end

  private
    def set_buyer
      @buyer = authorized_scope(Buyer.active).find(params[:buyer_id])
      authorize! @buyer, to: :update?
    end

    def back_to_buyer(**flash) = redirect_to(sell_buyer_path(@buyer), **flash)
end
