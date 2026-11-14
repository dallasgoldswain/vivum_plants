# Loads an item of the business the session acts for; another seller's item is a 404.
module StockItemScoped
  extend ActiveSupport::Concern

  included do
    requires_capability "seller.stock"
    before_action :set_stock_item
  end

  private
    def set_stock_item
      @stock_item = authorized_scope(StockItem.all).find(params[:stock_item_id])
      authorize! @stock_item, to: :show?
    end

    def ledger = Stock::Ledger.new(@stock_item, member: Current.user)
    def location_param(key = :location_id) = Current.seller.stock_locations.find_by(id: params[key])
    def back_to_item(**flash) = redirect_to(sell_stock_item_path(@stock_item), **flash)
end
