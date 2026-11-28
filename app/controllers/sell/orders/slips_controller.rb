# One order's slip (PK02, D242): business, order, recipient or Pickup, items and codes, no prices.
class Sell::Orders::SlipsController < Sell::BaseController
  include OrderScoped
  requires_capability "seller.packing"
  layout "print"

  def show
    @orders = [ @order ]
  end
end
