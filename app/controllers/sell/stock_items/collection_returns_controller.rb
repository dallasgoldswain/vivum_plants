# Takes a specimen back into the collection of the member who moved it in (D162).
class Sell::StockItems::CollectionReturnsController < Sell::BaseController
  include StockItemScoped

  def create
    ledger.to_collection!
    redirect_to plant_path(@stock_item.plant), notice: "Back in your collection."
  rescue Stock::Ledger::Refused => error
    back_to_item(alert: error.message)
  end
end
