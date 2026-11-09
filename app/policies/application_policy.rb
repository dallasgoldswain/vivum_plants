# Base class for all policies.
#
# Context:
# - user:       the signed-in account (nil for unauthenticated requests)
# - membership: the user's membership in the seller business the session is
#               acting for (nil when not acting for a seller)
#
# Every rule denies unless a policy explicitly allows it: Action Policy's
# defaults make index?, create? and manage? (the fallback for unknown rules)
# return false, and new? is an alias of create?.
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, allow_nil: true
  authorize :membership, optional: true

  private
    def platform_operator?
      user&.platform_operator?
    end

    # The record belongs to the seller the session is acting for.
    def current_seller_record?(record_seller_id = record.seller_id)
      membership.present? && record_seller_id == membership.seller_id
    end

    def owner?
      membership&.owner?
    end

    def manager_or_owner?
      membership&.manager_or_owner?
    end
end
