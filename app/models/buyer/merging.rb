# Two records for one person become one, by hand only (D178): aliases, holds, orders, addresses
# and consents move to the kept buyer and the other is removed.
module Buyer::Merging
  extend ActiveSupport::Concern

  def merge!(other)
    raise ArgumentError, "Choose another buyer of this business." if other == self || other.seller_id != seller_id || other.deleted?

    transaction do
      other.aliases.update_all(buyer_id: id)
      other.holds.update_all(buyer_id: id)
      other.orders.update_all(buyer_id: id)
      SaleLot.where(winner_buyer_id: other.id).update_all(winner_buyer_id: id)
      SaleLot.where(backup_buyer_id: other.id).update_all(backup_buyer_id: id)
      SaleClaim.where(buyer_id: other.id).update_all(buyer_id: id)
      other.addresses.update_all(buyer_id: id, default: false)
      other.consents.update_all(buyer_id: id)
      self.email ||= other.email
      save!
      Audit.record("buyer.merged", target: self, details: { merged_buyer_id: other.id })
      other.reload.destroy!
    end
  end
end
