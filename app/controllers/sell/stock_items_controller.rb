# Sell → Stock (SE01, D155, D156): the business's items with availability by location.
class Sell::StockItemsController < Sell::BaseController
  requires_capability "seller.stock"
  before_action :set_stock_item, only: %i[ show edit update ]

  def index
    authorize! StockItem
    @locations = Current.seller.stock_locations.active.by_name
    items = authorized_scope(StockItem.all).search(params[:q])
    items = params[:archived] == "1" ? items.where.not(archived_at: nil) : items.active
    if (location = @locations.find { it.id == params[:location].to_i })
      items = items.where(id: StockBalance.where(stock_location: location).where("saleable > 0 OR unavailable > 0").select(:stock_item_id))
    end
    @items = items.includes(:balances, cover_photo: { image_attachment: { blob: :variant_records } }).by_name.to_a
    @held = StockHold.current.where(stock_item_id: @items.map(&:id)).group(:stock_item_id).sum(:quantity)
    @items.select! { available(it).positive? } if params[:available] == "1"
  end

  def show
    @positions = @stock_item.positions
    @totals = Stock::Position.sum(@positions)
    @locations = Current.seller.stock_locations.active.by_name
    @holds = @stock_item.holds.where(state: "active").includes(:stock_location, :created_by, :buyer, { buyer_alias: :buyer }, order_line: :order).order(:expires_at)
    @movements = @stock_item.movements.includes(:stock_location, :to_location, :member).newest_first.limit(100)
    @photos = @stock_item.photos.with_attached_image.newest_first
    @quota = Photo.quota_for_seller(Current.seller)
  end

  def new
    authorize! StockItem, to: :create?
    @stock_item = Current.seller.stock_items.new(kind: params[:kind].presence_in(StockItem::KINDS) || "batch")
    @locations = Current.seller.stock_locations.active.by_name
  end

  def create
    authorize! StockItem, to: :create?
    @stock_item = Current.seller.stock_items.new(item_params)
    @locations = Current.seller.stock_locations.active.by_name
    quantity = params[:receive_quantity].to_i
    location = @locations.find { it.id == params[:receive_location_id].to_i }
    return render_new("Choose where the first #{quantity} arrive.") if quantity.positive? && location.nil?

    StockItem.transaction do
      @stock_item.save!
      Stock::Ledger.new(@stock_item, member: Current.user).receive!(quantity: quantity, location: location, reason: "First stock") if quantity.positive?
    end
    redirect_to sell_stock_item_path(@stock_item), notice: "#{@stock_item.name} added as #{@stock_item.code}."
  rescue ActiveRecord::RecordInvalid
    render_new
  rescue Stock::Ledger::Refused => error
    render_new(error.message)
  end

  def edit
    authorize! @stock_item, to: :update?
  end

  def update
    authorize! @stock_item, to: :update?
    if @stock_item.update(item_params.except(:kind))
      redirect_to sell_stock_item_path(@stock_item), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_stock_item
      @stock_item = authorized_scope(StockItem.all).find(params[:id])
      authorize! @stock_item, to: :show?
    end

    def item_params
      params.expect(stock_item: %i[ kind name cultivar botanical_name size price cost code notes ])
    end

    def available(item)
      [ item.balances.sum(&:saleable) - @held.fetch(item.id, 0), 0 ].max
    end

    def render_new(message = nil)
      @stock_item.errors.add(:base, message) if message
      render :new, status: :unprocessable_entity
    end
end
