# Releases holds whose time is up (D159, SE06). Availability already ignores them once the
# expiry passes; this records the expiry once in the ledger.
class ExpireStockHoldsJob < ApplicationJob
  queue_as :default

  def perform
    StockHold.due_to_expire.includes(:stock_item).find_each do |hold|
      Stock::Ledger.new(hold.stock_item, member: nil).expire!(hold)
    end
  end
end
