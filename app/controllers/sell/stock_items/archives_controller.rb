# Archives an item with nothing on hand or held; its history stays.
class Sell::StockItems::ArchivesController < Sell::BaseController
  include StockItemScoped
  before_action { authorize! @stock_item, to: :update? }

  def create
    return back_to_item(alert: "Only an item with nothing on hand or held can be archived.") if @stock_item.totals.on_hand.positive? || @stock_item.holds.current.exists?

    @stock_item.update!(archived_at: Time.current)
    redirect_to sell_stock_items_path, notice: "#{@stock_item.name} archived."
  end
end
