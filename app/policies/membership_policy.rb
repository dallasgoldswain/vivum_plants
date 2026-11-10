class MembershipPolicy < ApplicationPolicy
  # Members of the current seller can see who else works there.
  def index?
    membership.present?
  end

  def show?
    current_seller_record?
  end

  # Only owners add, change or remove members.
  def create?
    owner?
  end

  def update?
    current_seller_record? && owner?
  end

  # Owners may remove anyone; the model keeps the last owner (Membership#ensure_not_last_owner).
  def destroy?
    update?
  end

  relation_scope do |relation|
    next relation.none unless membership

    relation.where(seller_id: membership.seller_id)
  end
end
