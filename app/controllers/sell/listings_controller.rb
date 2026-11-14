# Sell → Listings (SE03, D164, D165, D168): what the business offers from its stock.
class Sell::ListingsController < Sell::BaseController
  requires_capability "seller.listings"
  before_action :set_listing, only: %i[ show edit update ]

  FILTERS = %w[ live draft ended sold_out ].freeze

  def index
    authorize! Listing
    listings = authorized_scope(Listing.all).includes(stock_item: :balances).newest_first
    @filter = params[:filter].presence_in(FILTERS) || "live"
    listings = @filter == "sold_out" ? listings.active : listings.where(state: @filter == "live" ? Listing::LIVE_STATES : @filter)
    listings = listings.where("LOWER(title) LIKE :q OR LOWER(reference) LIKE :q", q: "%#{Listing.sanitize_sql_like(params[:q].downcase)}%") if params[:q].present?
    @listings = listings.to_a
    @listings.select!(&:sold_out?) if @filter == "sold_out"
  end

  def show
    @cards = @listing.sale_cards.with_attached_image.limit(12)
  end

  def new
    authorize! Listing, to: :create?
    item = authorized_scope(StockItem.all, with: StockItemPolicy).active.find(params[:stock_item_id])
    if (live = item.listings.live.first)
      return redirect_to(sell_listing_path(live), notice: "#{item.code} is already listed as #{live.reference}.")
    end
    @listing = Listing.from_item(item)
  end

  def create
    authorize! Listing, to: :create?
    item = authorized_scope(StockItem.all, with: StockItemPolicy).active.find(params[:stock_item_id])
    @listing = Listing.from_item(item)
    @listing.assign_attributes(listing_params)
    if @listing.save
      @listing.activate! if params[:activate] == "1"
      redirect_to sell_listing_path(@listing), notice: "#{@listing.reference} #{@listing.active? ? 'is live' : 'saved as a draft'}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      redirect_to sell_listing_path(@listing), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_listing
      @listing = authorized_scope(Listing.all).find(params[:id])
      authorize! @listing
    end

    def listing_params
      permitted = params.expect(listing: [ :title, :price, :listed_quantity, :size, :details, :caption, photo_ids: [] ])
      permitted[:photo_ids] = Array(permitted[:photo_ids]).compact_blank
      permitted[:listed_quantity] = permitted[:listed_quantity].presence
      permitted
    end
end
