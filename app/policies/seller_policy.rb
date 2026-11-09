class SellerPolicy < ApplicationPolicy
  # Any member may view the business they are acting for.
  def show?
    current_seller_record?(record.id)
  end

  # Settings, billing and connections are owner-only.
  def update?
    show? && owner?
  end

  # A user may act for any business they belong to.
  def switch_to?
    user.present? && user.memberships.exists?(seller_id: record.id)
  end
end
