class Session < ApplicationRecord
  belongs_to :user
  belongs_to :seller, optional: true

  # The membership this session acts under, looked up fresh on each request so
  # removed members lose access immediately. Falls back to the user's only
  # membership when no seller has been chosen.
  def membership
    if seller_id
      user.memberships.find_by(seller_id: seller_id)
    else
      memberships = user.memberships.limit(2).to_a
      memberships.first if memberships.one?
    end
  end
end
