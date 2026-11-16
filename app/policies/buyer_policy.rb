# Buyers (D176): owners and managers manage buyers, contacts, addresses, consents,
# verification and merges; host/packers see names only, never contacts or addresses. Only
# owners export or delete a buyer's data (D177).
class BuyerPolicy < ApplicationPolicy
  def index? = membership.present?
  def create? = manager_or_owner?
  def show? = current_seller_record? && manager_or_owner? && !record.deleted?
  def update? = show?
  def see_contacts? = manager_or_owner?
  def erase? = show? && owner?

  alias_rule :edit?, :merge?, to: :update?
  alias_rule :export?, :destroy?, to: :erase?

  relation_scope { |relation| membership ? relation.where(seller_id: membership.seller_id) : relation.none }
end
