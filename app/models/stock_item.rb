# Something a seller sells (SE01, D155): a specimen (one unique plant) or a batch of
# identical plants. Quantities live in the ledger and balances, never on the item. A
# specimen can come from, and go back to, a member's collection (SE04, D162).
class StockItem < ApplicationRecord
  KINDS = %w[ specimen batch ].freeze

  belongs_to :seller
  belongs_to :plant, optional: true
  belongs_to :moved_by, class_name: "User", optional: true
  belongs_to :cover_photo, class_name: "Photo", optional: true
  has_many :balances, class_name: "StockBalance", dependent: :delete_all
  has_many :holds, class_name: "StockHold", dependent: :destroy
  has_many :movements, class_name: "StockMovement", dependent: :delete_all
  has_many :photos, dependent: :destroy
  has_many :listings, dependent: :destroy

  enum :kind, KINDS.index_by(&:itself), validate: true

  normalizes :name, :cultivar, :botanical_name, :size, :code, with: ->(value) { value.squish.presence }

  validates :name, presence: true, length: { maximum: 120 }
  validates :cultivar, :botanical_name, length: { maximum: 120 }
  validates :size, length: { maximum: 60 }
  validates :code, length: { maximum: 30 }, format: { with: /\A[A-Za-z0-9][A-Za-z0-9\-_.\/]*\z/, message: "can use letters, numbers and - _ . /" }, allow_nil: true
  validate :code_unique_in_seller
  validates :price_cents, :cost_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :notes, length: { maximum: 2000 }

  before_create :assign_code

  scope :active, -> { where(archived_at: nil) }
  scope :by_name, -> { order(Arel.sql("LOWER(name)"), :id) }
  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.squish.downcase)}%"
    query.blank? ? all : where("LOWER(name) LIKE :term OR LOWER(code) LIKE :term OR LOWER(COALESCE(cultivar, '')) LIKE :term OR LOWER(COALESCE(botanical_name, '')) LIKE :term", term: term)
  }

  # Rands in the forms; cents in the database.
  def price = price_cents && price_cents / 100.0
  def price=(value)
    self.price_cents = rands_to_cents(value)
  end

  def cost = cost_cents && cost_cents / 100.0
  def cost=(value)
    self.cost_cents = rands_to_cents(value)
  end

  def archived? = archived_at.present?
  def label = [ name, cultivar && "‘#{cultivar}’" ].compact.join(" ")

  # Balances by location with what's held there: [Stock::Position, …].
  def positions
    held = holds.current.group(:stock_location_id).sum(:quantity)
    balances.includes(:stock_location).sort_by { it.stock_location.name.downcase }.map do |balance|
      Stock::Position.new(balance.stock_location, balance.saleable, balance.unavailable, held.fetch(balance.stock_location_id, 0))
    end
  end

  def totals = Stock::Position.sum(positions)

  private
    def assign_code
      return if code.present?

      self.number = seller.class.connection.select_value(
        seller.class.sanitize_sql_array([ "UPDATE sellers SET last_stock_number = last_stock_number + 1 WHERE id = ? RETURNING last_stock_number", seller_id ])
      ).to_i
      self.code = format("S-%04d", number)
    end

    def code_unique_in_seller
      return if code.blank? || seller.nil?

      taken = seller.stock_items.where("LOWER(code) = ?", code.downcase).where.not(id: id).exists?
      errors.add(:code, "is already used for another item") if taken
    end

    def rands_to_cents(value)
      value = value.to_s.delete(" ,R").strip
      value.empty? ? nil : (BigDecimal(value) * 100).round.to_i
    rescue ArgumentError
      -1
    end
end
