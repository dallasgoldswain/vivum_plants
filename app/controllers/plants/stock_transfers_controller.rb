# Moves a plant from your collection into the stock of the business you're acting for, as a
# linked specimen (SE04, D162). Owners and managers only, since it receives stock.
class Plants::StockTransfersController < ApplicationController
  include PlantScoped
  requires_capability "seller.stock"
  before_action :require_stock_role

  def new
    @locations = Current.seller.stock_locations.active.by_name
  end

  def create
    location = Current.seller.stock_locations.active.find_by(id: params[:location_id])
    item = Stock::Transfer.from_plant!(@plant, seller: Current.seller, location: location, member: Current.user, price: params[:price])
    redirect_to sell_stock_item_path(item), notice: "#{@plant.display_name} is now #{item.code} in #{Current.seller.name} stock."
  rescue Stock::Transfer::Refused, Stock::Ledger::Refused => error
    redirect_to new_plant_stock_transfer_path(@plant), alert: error.message
  end

  private
    def require_stock_role
      raise ActionController::RoutingError, "Not Found" unless Current.membership&.manager_or_owner?
    end
end
