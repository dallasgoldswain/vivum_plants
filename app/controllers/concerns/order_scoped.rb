# Loads an order of the business the session acts for; another seller's order is a 404.
module OrderScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "seller.orders"
    before_action :set_order
  end

  private
    def set_order
      @order = authorized_scope(Order.all).find(params[:order_id])
      authorize! @order, to: :update?
    end

    def back_to_order(**flash) = redirect_to(sell_order_path(@order), **flash)

    # Runs an order action and goes back to the order with its outcome.
    def change_order(notice)
      yield
      back_to_order(notice: notice)
    rescue Order::Reserving::Refused => error
      back_to_order(alert: error.message)
    end

    def time_param(name) = (Time.zone.parse(params[name].to_s) if params[name].present?)
end
