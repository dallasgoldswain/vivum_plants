# Plants sent back after fulfilment (SE06, D196).
class Sell::Orders::ReturnsController < Sell::BaseController
  include OrderScoped

  def create
    line = @order.lines.find(params[:line_id])
    location = Current.seller.stock_locations.find_by(id: params[:stock_location_id]) or return back_to_order(alert: "Choose a location.")
    change_order("Return recorded.") do
      @order.record_return!(line, quantity: params[:quantity], location: location, outcome: params[:outcome], reason: params[:reason], member: Current.user)
    end
  end
end
