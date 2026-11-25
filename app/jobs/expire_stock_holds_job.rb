# Releases holds whose time is up (D159, SE06). Availability already ignores them once the
# expiry passes; this records the expiry once in the ledger. Live sale wins and claims whose
# hold ran out at the end of the backup window are then marked returned to stock (D213).
class ExpireStockHoldsJob < ApplicationJob
  queue_as :default

  def perform
    StockHold.due_to_expire.includes(:stock_item).find_each do |hold|
      Stock::Ledger.new(hold.stock_item, member: nil).expire!(hold)
    end
    SaleLot.settle_expired!
    SaleClaim.settle_expired!
  end
end
