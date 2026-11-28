# Sell → To ship (PK01, PK02, D240–D243): paid orders waiting to go, oldest payment first.
# Owners and managers tick them packed, print slips and mark them shipped or collected.
class Sell::ToShipController < Sell::BaseController
  requires_capability "seller.orders"
  requires_capability "seller.packing"
  layout "print", only: :slips
  before_action { authorize! Order, to: :index? }
  before_action :set_orders

  def show
  end

  # Print all: a slip for every order on the list.
  def slips
    render "sell/orders/slips/show"
  end

  private
    def set_orders
      @orders = authorized_scope(Order.all).to_ship.includes(lines: :stock_item)
      @orders = @orders.where.not(delivery_method: "pickup") unless capability?("shipping.pickup")
    end
end
