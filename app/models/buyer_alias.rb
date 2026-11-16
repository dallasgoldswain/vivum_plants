# A name a buyer goes by, such as in a WhatsApp group (BY02, D172). Linked to a buyer only by
# hand; matching names never merge.
class BuyerAlias < ApplicationRecord
  belongs_to :seller
  belongs_to :buyer, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :holds, class_name: "StockHold", dependent: :nullify

  normalizes :name, :group_name, with: ->(value) { value.squish.presence }

  validates :name, presence: true, length: { maximum: 120 }
  validates :group_name, length: { maximum: 120 }
  validate :buyer_of_same_seller

  scope :unlinked, -> { where(buyer_id: nil) }
  scope :by_name, -> { order(Arel.sql("LOWER(buyer_aliases.name)"), :id) }

  def label = group_name ? "#{name} (#{group_name})" : name

  private
    def buyer_of_same_seller
      errors.add(:buyer, "belongs to another business") if buyer && buyer.seller_id != seller_id
    end
end
