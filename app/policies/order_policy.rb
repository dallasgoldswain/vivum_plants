# Orders are for owners and managers (D185); host/packers get their own view with packing
# (B27), without prices or contacts.
class OrderPolicy < ApplicationPolicy
  def index? = manager_or_owner?
  def create? = manager_or_owner?
  def show? = current_seller_record? && manager_or_owner?
  def update? = show?

  relation_scope { |relation| membership ? relation.where(seller_id: membership.seller_id) : relation.none }
end
