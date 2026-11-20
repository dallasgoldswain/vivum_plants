# Reserves an order's lines until one seller-chosen time (D180, D14), or moves that time.
class Sell::Orders::ReservationsController < Sell::BaseController
  include OrderScoped
  requires_capability "seller.reservations"

  def create
    change_order("Reserved until #{params[:expires_at].present? ? l(time_param(:expires_at), format: :short) : '—'}.") do
      @order.reserve!(expires_at: time_param(:expires_at), member: Current.user)
    end
  end
end
