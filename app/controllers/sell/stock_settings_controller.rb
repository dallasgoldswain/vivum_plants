# The business's stock settings: default collection and delivery details for new listings
# (D168). Owners and managers.
class Sell::StockSettingsController < Sell::BaseController
  requires_capability "seller.listings"
  before_action { authorize! Listing, to: :create? }

  def edit
  end

  def update
    if Current.seller.update(listing_details: params[:listing_details].to_s.strip.presence)
      redirect_to sell_listings_path, notice: "Settings saved. New listings start with these details."
    else
      redirect_to edit_sell_stock_settings_path, alert: Current.seller.errors.full_messages.to_sentence
    end
  end
end
