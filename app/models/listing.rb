# What a seller offers from one stock item (SE03, D164, D165): its own reference, title,
# price, photos and details. It never holds stock: it shows the item's available stock,
# optionally capped, and reads as sold out at 0.
class Listing < ApplicationRecord
  STATES = %w[ draft active paused ended ].freeze
  LIVE_STATES = %w[ active paused ].freeze

  belongs_to :seller
  belongs_to :stock_item
  has_many :sale_cards, -> { order(created_at: :desc) }, dependent: :destroy

  enum :state, STATES.index_by(&:itself), validate: true, default: "draft"

  normalizes :title, :size, with: ->(value) { value.squish.presence }
  normalizes :details, :caption, with: ->(value) { value.strip.presence }

  validates :title, presence: true, length: { maximum: 120 }
  validates :size, length: { maximum: 60 }
  validates :details, length: { maximum: 500 }
  validates :caption, length: { maximum: 1000 }
  validates :price_cents, presence: { message: "is needed to list it" }, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: false
  validates :listed_quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :one_live_listing_per_item
  validate :photos_of_the_item
  validate { errors.add(:stock_item, "must belong to this business") if stock_item && stock_item.seller_id != seller_id }

  before_validation :assign_reference, on: :create

  scope :live, -> { where(state: LIVE_STATES) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def self.from_item(item)
    item.seller.listings.new(stock_item: item, title: item.label, price_cents: item.price_cents, size: item.size,
      details: item.seller.listing_details, photo_ids: [ item.cover_photo_id ].compact)
  end

  def price = price_cents && price_cents / 100.0

  def price=(value)
    value = value.to_s.delete(" ,R").strip
    self.price_cents = value.empty? ? nil : (BigDecimal(value) * 100).round.to_i
  rescue ArgumentError
    self.price_cents = -1
  end

  def live? = LIVE_STATES.include?(state)
  def available = [ stock_item.totals.available, listed_quantity ].compact.min
  def sold_out? = active? && available.zero?
  def sellable? = active? && available.positive?
  def display_state = sold_out? ? "sold out" : state

  def photos = stock_item.photos.where(id: photo_ids).with_attached_image.sort_by { photo_ids.index(it.id) }
  def card_photo = photos.first

  # The caption the seller shares: their own text, or the template (D168).
  def caption_text = caption.presence || default_caption

  def default_caption
    [ title, [ rands(price_cents), size ].compact.join(" · "), details, "Ref #{reference}" ].compact_blank.join("\n")
  end

  def activate! = update!(state: "active", ended_at: nil)
  def pause! = update!(state: "paused")
  def end! = update!(state: "ended", ended_at: Time.current)

  private
    def rands(cents) = ActiveSupport::NumberHelper.number_to_currency(cents / 100.0, unit: "R", delimiter: " ", precision: (cents % 100).zero? ? 0 : 2, format: "%u%n")

    def assign_reference
      return if reference.present? || seller.nil?

      self.number = seller.class.connection.select_value(
        seller.class.sanitize_sql_array([ "UPDATE sellers SET last_listing_number = last_listing_number + 1 WHERE id = ? RETURNING last_listing_number", seller_id ])
      ).to_i
      self.reference = format("L-%04d", number)
    end

    def one_live_listing_per_item
      return unless live? && stock_item

      clash = Listing.live.where(stock_item_id: stock_item_id).where.not(id: id).first
      errors.add(:base, "#{stock_item.code} already has a live listing (#{clash.reference}). End it first.") if clash
    end

    def photos_of_the_item
      self.photo_ids = photo_ids.map(&:to_i).uniq
      errors.add(:photo_ids, "must be photos of this item") if stock_item && (photo_ids - stock_item.photos.ids).any?
    end
end
