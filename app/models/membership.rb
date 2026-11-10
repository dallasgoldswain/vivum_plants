class Membership < ApplicationRecord
  belongs_to :seller
  belongs_to :user

  # Owner: everything, including billing, connections and members.
  # Manager: stock, sales, orders, payment review, packing, requests.
  # Host/Packer: Host View, Quick Claim, packing, pickup confirmation.
  enum :role, { owner: "owner", manager: "manager", host_packer: "host_packer" }, validate: true

  validates :user_id, uniqueness: { scope: :seller_id }
  validate :keeps_an_owner, on: :update

  # A business always keeps at least one owner (D61).
  before_destroy :ensure_not_last_owner

  def manager_or_owner?
    owner? || manager?
  end

  def last_owner?
    owner? && !seller.memberships.owner.where.not(id: id).exists?
  end

  private
    def keeps_an_owner
      if role_changed?(from: "owner") && !seller.memberships.owner.where.not(id: id).exists?
        errors.add(:role, "can't change: a business needs at least one owner")
      end
    end

    def ensure_not_last_owner
      return if destroyed_by_association || !last_owner?

      errors.add(:base, "A business needs at least one owner")
      throw :abort
    end
end
