# Live sales (D217): owners and managers create, edit and run sessions and settle results.
# Host/packers run Host View and Quick Claim for the sessions they host, where they see the
# bids and claim prices, and nothing else of the business's prices.
class SaleSessionPolicy < ApplicationPolicy
  def index? = membership.present?
  def create? = manager_or_owner?
  def show? = current_seller_record? && manager_or_owner?
  def update? = show?
  def host? = current_seller_record? && (manager_or_owner? || record.host_member_id == user&.id)

  alias_rule :edit?, to: :update?

  relation_scope do |relation|
    next relation.none unless membership

    sessions = relation.where(seller_id: membership.seller_id)
    manager_or_owner? ? sessions : sessions.where(host_member_id: user.id)
  end
end
