# The business's stock locations (D157). Owners and managers add and rename them; a location
# with nothing in it can be archived.
class Sell::StockLocationsController < Sell::BaseController
  requires_capability "seller.stock"
  before_action { authorize! StockItem, to: (action_name == "index" ? :index? : :create?) }

  def index
    @locations = Current.seller.stock_locations.by_name
    @counts = StockBalance.where(stock_location: @locations).group(:stock_location_id).sum("saleable + unavailable")
  end

  def create
    location = Current.seller.stock_locations.new(name: params[:name])
    if location.save
      redirect_to (params[:return_to] == "stock" ? sell_stock_items_path : sell_stock_locations_path), notice: "#{location.name} added."
    else
      redirect_to sell_stock_locations_path, alert: location.errors.full_messages.to_sentence
    end
  end

  def update
    location = Current.seller.stock_locations.find(params[:id])
    if params[:archive] == "1"
      return redirect_to(sell_stock_locations_path, alert: "Move its stock out first.") if location.stocked?

      location.update!(archived_at: Time.current)
    elsif params[:restore] == "1"
      location.update!(archived_at: nil)
    else
      return redirect_to(sell_stock_locations_path, alert: location.errors.full_messages.to_sentence) unless location.update(name: params[:name])
    end
    redirect_to sell_stock_locations_path, notice: "Saved."
  end
end
