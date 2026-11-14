# Where a seller keeps stock (D157): a greenhouse, a shelf, a shop. Archived locations are
# hidden from pickers but keep their history.
class StockLocation < ApplicationRecord
  belongs_to :seller
  has_many :balances, class_name: "StockBalance", dependent: :restrict_with_error

  normalizes :name, with: ->(value) { value.squish.presence }
  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :seller_id, case_sensitive: false }

  scope :active, -> { where(archived_at: nil) }
  scope :by_name, -> { order(Arel.sql("LOWER(name)")) }

  def archived? = archived_at.present?
  def stocked? = balances.where("saleable > 0 OR unavailable > 0").exists?
end
