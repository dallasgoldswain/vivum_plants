# Seller stock (D161): every member sees items and availability; owners and managers add
# and edit items, prices and costs, receive, count and hold; host/packers can move stock,
# mark it unavailable or available and record losses, but never see prices or costs.
class StockItemPolicy < ApplicationPolicy
  def index? = membership.present?
  def show? = current_seller_record?
  def create? = manager_or_owner?
  def update? = current_seller_record? && manager_or_owner?
  def handle? = current_seller_record?
  def see_prices? = manager_or_owner?

  alias_rule :edit?, :manage_stock?, to: :update?

  relation_scope { |relation| membership ? relation.where(seller_id: membership.seller_id) : relation.none }
end
