# Adds, changes and removes an order's lines (D179, D183). On a reserved order each change
# adjusts its holds in the same transaction.
class Sell::Orders::LinesController < Sell::BaseController
  include OrderScoped
  before_action :set_line, only: %i[ update destroy ]

  def create
    item = Current.seller.stock_items.active.find_by(id: params[:stock_item_id]) or return back_to_order(alert: "Choose an item.")
    listing = item.listings.live.first
    price = params[:price].present? ? Order.cents(params[:price]) : nil
    change_order("Added #{item.code}.") do
      @order.add_line!(item: item, quantity: params[:quantity].presence || 1, listing: listing, price_cents: price, member: Current.user)
    end
  end

  def update
    change_order("Saved.") do
      @order.change_quantity!(@line, quantity: params[:quantity], member: Current.user) if params[:quantity].present?
      if params[:price].present?
        cents = Order.cents(params[:price])
        @order.change_price!(@line, price_cents: cents, reason: params[:price_reason], member: Current.user) unless cents == @line.unit_price_cents
      end
    end
  end

  def destroy
    change_order(@order.draft? ? "Removed." : "Line cancelled.") do
      @order.remove_line!(@line, reason: params[:reason], member: Current.user)
    end
  end

  private
    def set_line = @line = @order.lines.find(params[:id])
end
