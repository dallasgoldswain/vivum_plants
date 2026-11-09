# Switches which seller business the current session acts for.
class CurrentSellersController < ApplicationController
  def update
    seller = Seller.find(params[:seller_id])
    authorize! seller, to: :switch_to?

    Current.session.update!(seller: seller)
    redirect_back_or_to root_path, notice: "Now working as #{seller.name}."
  end
end
