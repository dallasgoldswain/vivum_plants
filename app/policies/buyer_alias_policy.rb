# Aliases (D172, D176): every member can see and add them (for live sales later); only owners
# and managers link, unlink, rename or remove them.
class BuyerAliasPolicy < ApplicationPolicy
  def index? = membership.present?
  def create? = membership.present?
  def update? = current_seller_record? && manager_or_owner?

  alias_rule :destroy?, to: :update?

  relation_scope { |relation| membership ? relation.where(seller_id: membership.seller_id) : relation.none }
end
