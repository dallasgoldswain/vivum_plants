class Membership < ApplicationRecord
  belongs_to :seller
  belongs_to :user

  # Owner: everything, including billing, connections and members.
  # Manager: stock, sales, orders, payment review, packing, requests.
  # Host/Packer: Host View, Quick Claim, packing, pickup confirmation.
  enum :role, { owner: "owner", manager: "manager", host_packer: "host_packer" }, validate: true

  validates :user_id, uniqueness: { scope: :seller_id }

  def manager_or_owner?
    owner? || manager?
  end
end
