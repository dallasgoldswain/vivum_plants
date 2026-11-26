# Splits an unpaid order (SC02, D224): the chosen lines move, with their holds, to a new
# order for the same buyer.
class Sell::Orders::SplitsController < Sell::BaseController
  include OrderScoped
  requires_capability "seller.closeout"

  def create
    split = @order.split!(line_ids: params[:line_ids], reason: params[:reason], member: Current.user)
    back_to_order(notice: "Moved to #{split.reference}.")
  rescue Order::Reserving::Refused => error
    back_to_order(alert: error.message)
  end
end
