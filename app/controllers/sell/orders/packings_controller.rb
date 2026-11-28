# Packed (D241): an optional tick before shipping, undone with Unpack until the order ships.
class Sell::Orders::PackingsController < Sell::BaseController
  include OrderScoped
  requires_capability "seller.packing"

  def create
    change_order("#{@order.reference} packed.") { @order.pack!(member: Current.user) }
  end

  def destroy
    change_order("#{@order.reference} is no longer packed.") { @order.unpack!(member: Current.user) }
  end
end
