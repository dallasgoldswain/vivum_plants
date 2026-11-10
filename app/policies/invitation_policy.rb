# Staff invites for the seller the session acts for. Only owners invite, resend and revoke.
# Seller invites are issued by operators in /madmin, which has its own gate.
class InvitationPolicy < ApplicationPolicy
  def create?
    owner? && record.staff? && current_seller_record?
  end

  def resend? = create?
  def revoke? = create?

  relation_scope do |relation|
    next relation.none unless membership

    relation.staff.where(seller_id: membership.seller_id)
  end
end
