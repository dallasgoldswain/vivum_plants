# Sale cards are kept for 90 days (D170); a new one can be made at any time.
class DeleteOldSaleCardsJob < ApplicationJob
  queue_as :default

  def perform
    SaleCard.expired.find_each(&:destroy!)
  end
end
