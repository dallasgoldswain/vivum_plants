# Listings and sale cards are for owners and managers of the business (D170).
class ListingPolicy < ApplicationPolicy
  def index? = manager_or_owner?
  def create? = manager_or_owner?
  def show? = current_seller_record? && manager_or_owner?
  def update? = show?

  alias_rule :edit?, to: :update?

  relation_scope { |relation| membership ? relation.where(seller_id: membership.seller_id) : relation.none }
end
