# A rendered sale card image (SE07, D166, D167), stored with the title, price and photo it
# shows, and the business name, card link and logo (D255), so a later change can flag it
# as stale. Kept for 90 days.
class SaleCard < ApplicationRecord
  FORMATS = { "square" => [ 1080, 1080 ], "status" => [ 1080, 1920 ] }.freeze
  FILE_TYPES = %w[ jpeg png ].freeze
  KEEP_FOR = 90.days

  belongs_to :listing
  belongs_to :created_by, class_name: "User", optional: true
  has_one_attached :image

  validates :format, inclusion: { in: FORMATS.keys }
  validates :file_type, inclusion: { in: FILE_TYPES }

  scope :expired, -> { where(created_at: ...KEEP_FOR.ago) }

  # Renders and stores a card for the listing as it is now.
  def self.render!(listing, format:, file_type:, created_by:)
    photo = listing.card_photo
    logo = listing.seller.shown_logo_blob
    card = listing.sale_cards.new(format: format, file_type: file_type, price_cents: listing.price_cents, title: listing.title, photo_id: photo&.id,
                                  business_label: listing.seller.card_label, logo_blob_id: logo&.id, created_by: created_by)
    raise ActiveRecord::RecordInvalid, card unless card.valid?

    data = SaleCard::Renderer.new(listing, photo: photo, logo: logo, size: FORMATS.fetch(format), file_type: file_type).call
    card.image.attach(io: StringIO.new(data), filename: "#{listing.reference}-#{format}.#{file_type == 'png' ? 'png' : 'jpg'}", content_type: "image/#{file_type}")
    card.save!
    card
  end

  def width = FORMATS.fetch(format).first
  def height = FORMATS.fetch(format).last
  def filename = image.filename.to_s

  # Why the card no longer matches the listing (D167), or nil.
  def stale_reason
    if !listing.sellable? then "The listing is #{listing.display_state}."
    elsif listing.price_cents != price_cents then "Shows #{rands(price_cents)}; the price is now #{rands(listing.price_cents)}."
    elsif listing.title != title then "Shows an older name."
    elsif listing.card_photo&.id != photo_id then "Shows a different photo."
    elsif listing.seller.card_label != business_label || listing.seller.shown_logo_blob&.id != logo_blob_id then "Shows older business details."
    end
  end

  private
    def rands(cents) = ActiveSupport::NumberHelper.number_to_currency(cents / 100.0, unit: "R", delimiter: " ", precision: (cents % 100).zero? ? 0 : 2, format: "%u%n")
end
