# Makes a sale card for a listing as it is now (SE07, D166), and serves a card's image.
class Sell::Listings::SaleCardsController < Sell::BaseController
  requires_capability "seller.sale_cards"
  before_action :set_listing

  def create
    format = params[:format_name].presence_in(SaleCard::FORMATS.keys) || "square"
    file_type = params[:file_type].presence_in(SaleCard::FILE_TYPES) || "jpeg"
    return redirect_to(sell_listing_path(@listing), alert: "Only a live listing with stock can have a card.") unless @listing.sellable?
    return redirect_to(sell_listing_path(@listing), alert: "Your business has reached its photo limit.") if Photo.quota_for_seller(Current.seller).full?

    card = SaleCard.render!(@listing, format: format, file_type: file_type, created_by: Current.user)
    redirect_to sell_listing_path(@listing, anchor: "card-#{card.id}"), notice: "Card ready to share."
  end

  def show
    card = @listing.sale_cards.find(params[:id])
    send_data card.image.download, filename: card.filename, type: card.image.content_type, disposition: (params[:download] ? "attachment" : "inline")
  end

  private
    def set_listing
      @listing = authorized_scope(Listing.all).find(params[:listing_id])
      authorize! @listing, to: :show?
    end
end
