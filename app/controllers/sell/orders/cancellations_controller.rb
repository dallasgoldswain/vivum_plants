# Cancels an open order with a reason (D183); its holds release once.
class Sell::Orders::CancellationsController < Sell::BaseController
  include OrderScoped

  def create
    change_order("#{@order.reference} cancelled.") { @order.cancel!(reason: params[:reason], member: Current.user) }
  end
end
