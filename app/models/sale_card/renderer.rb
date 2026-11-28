require "vips"

# Draws a sale card with libvips (SE07, D166): the photo on top and a panel with the name,
# the price and a line with the size, business name and card link, beside the logo (D253). The price is drawn on its own and
# sized first, so a long name shrinks or is shortened rather than hiding it. Nothing private
# is drawn.
class SaleCard::Renderer
  BACKGROUND = [ 244, 242, 236 ].freeze
  PHOTOLESS = [ 30, 58, 43 ].freeze
  INK = "#1c3a2b"
  MUTED = "#55645a"
  MARGIN = 56
  NAME_SIZES = [ 56, 48, 40 ].freeze

  LOGO_BOX = [ 220, 88 ].freeze

  def initialize(listing, photo:, size:, file_type:, logo: nil)
    @listing = listing
    @photo = photo
    @logo = logo
    @width, @height = size
    @file_type = file_type
  end

  def call
    panel = @height > @width ? 460 : 330
    canvas = Vips::Image.black(@width, @height, bands: 3).new_from_image(BACKGROUND.to_a).copy(interpretation: :srgb).cast(:uchar)
    canvas = place_photo(canvas, @height - panel)

    text_width = @width - (2 * MARGIN)
    price = text("<b>#{escape(rands(@listing.price_cents))}</b>", 76, text_width)
    logo = logo_image
    logo_room = logo ? logo.width + 24 : 0
    meta = text(escape([ @listing.size, @listing.seller.card_label ].compact_blank.join(" · ")), 32, text_width - logo_room, MUTED)
    row = [ meta.height, logo&.height.to_i ].max
    top = @height - panel + 44
    room = panel - 44 - 40 - price.height - 16 - row - 20
    name = fit_name(text_width, room)

    canvas = canvas.composite2(name, :over, x: MARGIN, y: top)
    canvas = canvas.composite2(price, :over, x: MARGIN, y: top + name.height + 16)
    row_top = @height - 40 - row
    canvas = canvas.composite2(logo, :over, x: MARGIN, y: row_top + ((row - logo.height) / 2)) if logo
    canvas = canvas.composite2(meta, :over, x: MARGIN + logo_room, y: row_top + ((row - meta.height) / 2))
    canvas = canvas.flatten(background: BACKGROUND.to_a) if canvas.has_alpha?
    canvas = canvas.cast(:uchar)
    @file_type == "png" ? canvas.write_to_buffer(".png") : canvas.write_to_buffer(".jpg", Q: 88, strip: true)
  end

  private
    def place_photo(canvas, photo_height)
      return canvas.draw_rect(PHOTOLESS.to_a, 0, 0, @width, photo_height, fill: true) unless @photo&.image&.attached?

      image = Vips::Image.thumbnail_buffer(@photo.image.download, @width, height: photo_height, crop: :centre)
      image = image.colourspace(:srgb)
      image = image.flatten(background: BACKGROUND.to_a) if image.has_alpha?
      canvas.insert(image.cast(:uchar), (@width - image.width) / 2, 0)
    end

    # Fitted into its box at its own shape, never cropped (D251).
    def logo_image
      return unless @logo

      image = Vips::Image.thumbnail_buffer(@logo.download, LOGO_BOX.first, height: LOGO_BOX.last).colourspace(:srgb)
      image.bands == 4 ? image : image.bandjoin(255)
    end

    # The largest size at which the name fits its room; shortened with an ellipsis if even
    # the smallest is too tall.
    def fit_name(width, room)
      name = @listing.title.to_s
      NAME_SIZES.each do |size|
        image = text("<b>#{escape(name)}</b>", size, width)
        return image if image.height <= room
      end
      while name.length > 1
        name = name[0...-2].rstrip
        image = text("<b>#{escape(name)}…</b>", NAME_SIZES.last, width)
        return image if image.height <= room
      end
      text("…", NAME_SIZES.last, width)
    end

    def text(markup, size, width, color = INK)
      Vips::Image.text(%(<span foreground="#{color}">#{markup}</span>), font: "sans #{size}", width: width, dpi: 72, rgba: true)
    end

    def escape(value) = ERB::Util.html_escape(value.to_s)
    def rands(cents) = ActiveSupport::NumberHelper.number_to_currency(cents / 100.0, unit: "R", delimiter: " ", precision: (cents % 100).zero? ? 0 : 2, format: "%u%n")
end
