require "vips"

# The business's standard identity (BR01, D250–D258): a logo and Instagram, Facebook,
# YouTube and WhatsApp links, each shown or hidden. Sale cards, receipts and slips show
# them; a hidden or empty link never renders. Needs no paid plan.
module Seller::Identity
  extend ActiveSupport::Concern

  LOGO_TYPES = %w[ image/png image/jpeg image/webp ].freeze
  LOGO_MAX_SIZE = 5.megabytes
  LOGO_BOX = 800
  LINKS = %w[ instagram facebook youtube whatsapp ].freeze
  LINK_NAMES = { "instagram" => "Instagram", "facebook" => "Facebook", "youtube" => "YouTube", "whatsapp" => "WhatsApp" }.freeze

  Link = Data.define(:key, :name, :text, :url)

  class LogoRejected < StandardError; end

  included do
    # Replacing or removing the logo keeps the old file, so receipts issued with it still
    # show it (D255).
    has_one_attached :logo, dependent: false

    normalizes :instagram_url, with: ->(value) { Seller::Identity.instagram(value) || value.strip.presence }
    normalizes :facebook_url, with: ->(value) { Seller::Identity.facebook(value) || value.strip.presence }
    normalizes :youtube_url, with: ->(value) { Seller::Identity.youtube(value) || value.strip.presence }
    normalizes :whatsapp_number, with: ->(value) { Seller::Identity.whatsapp(value) || value.strip.presence }
    normalizes :card_link, with: ->(value) { value.presence }

    validates :instagram_url, format: { with: %r{\Ahttps://www\.instagram\.com/[A-Za-z0-9._]{1,30}\z}, message: "must be an Instagram @handle or instagram.com link" }, allow_nil: true
    validates :facebook_url, format: { with: %r{\Ahttps://www\.facebook\.com/([A-Za-z0-9.\-]{1,50}|profile\.php\?id=\d{1,20})\z}, message: "must be a Facebook page name or facebook.com link" }, allow_nil: true
    validates :youtube_url, format: { with: %r{\Ahttps://www\.youtube\.com/(@[A-Za-z0-9._\-]{3,30}|channel/UC[A-Za-z0-9_\-]{22}|c/[A-Za-z0-9._\-]{1,100})\z}, message: "must be a YouTube @handle or youtube.com link" }, allow_nil: true
    validates :whatsapp_number, format: { with: /\A\+27[1-9]\d{8}\z/, message: "must be a South African number, like 082 123 4567" }, allow_nil: true
    validates :card_link, inclusion: { in: LINKS }, allow_nil: true
  end

  class_methods do
    def link_column(key) = key == "whatsapp" ? :whatsapp_number : :"#{key}_url"
  end

  # Each accepts an @handle or a link for its own site only, and returns the clean URL, or
  # nil if the value isn't one (D256).
  def self.instagram(value)
    value = value.to_s.strip
    handle = value[%r{\A(?:https?://)?(?:www\.|m\.)?instagram\.com/([^/?#]+)/?(?:[?#].*)?\z}i, 1] || value[/\A@?([A-Za-z0-9._]{1,30})\z/, 1]
    "https://www.instagram.com/#{handle}" if handle&.match?(/\A[A-Za-z0-9._]{1,30}\z/)
  end

  def self.facebook(value)
    value = value.to_s.strip
    path = value[%r{\A(?:https?://)?(?:www\.|m\.|web\.)?(?:facebook|fb)\.com/(profile\.php\?id=\d{1,20}|[^/?#]+)/?(?:[?#].*)?\z}i, 1] || value[/\A@?([A-Za-z0-9.\-]{1,50})\z/, 1]
    "https://www.facebook.com/#{path}" if path&.match?(/\A([A-Za-z0-9.\-]{1,50}|profile\.php\?id=\d{1,20})\z/)
  end

  def self.youtube(value)
    value = value.to_s.strip
    path = value[%r{\A(?:https?://)?(?:www\.|m\.)?youtube\.com/(@[^/?#]+|channel/[^/?#]+|c/[^/?#]+)/?(?:[?#].*)?\z}i, 1] || value[/\A(@[A-Za-z0-9._\-]{3,30})\z/, 1]
    "https://www.youtube.com/#{path}" if path&.match?(%r{\A(@[A-Za-z0-9._\-]{3,30}|channel/UC[A-Za-z0-9_\-]{22}|c/[A-Za-z0-9._\-]{1,100})\z})
  end

  # A South African number, stored as +27 and nine digits.
  def self.whatsapp(value)
    digits = value.to_s.gsub(/[\s\-().]/, "")
    "+27#{$1}" if digits =~ /\A(?:\+27|0027|27|0)([1-9]\d{8})\z/
  end

  def self.link_for(key, value)
    case key
    when "instagram" then Link.new(key, LINK_NAMES[key], "@#{value.delete_prefix('https://www.instagram.com/')}", value)
    when "facebook" then Link.new(key, LINK_NAMES[key], value.delete_prefix("https://www."), value)
    when "youtube"
      path = value.delete_prefix("https://www.youtube.com/")
      Link.new(key, LINK_NAMES[key], path.start_with?("@") ? path : "youtube.com/#{path}", value)
    when "whatsapp"
      local = value.delete_prefix("+27")
      Link.new(key, LINK_NAMES[key], "0#{local[0, 2]} #{local[2, 3]} #{local[5, 4]}", "https://wa.me/27#{local}")
    end
  end

  # Every link that's filled in and valid, shown or not.
  def links
    LINKS.filter_map do |key|
      value = public_send(self.class.link_column(key))
      Seller::Identity.link_for(key, value) if value.present? && Seller::Identity.public_send(key, value) == value
    end
  end

  def shown_links
    return [] unless Capabilities.enabled?("seller.social_links", seller: self)

    links.select { public_send(:"show_#{it.key}") }
  end

  # The one link a sale card shows beside the name (D253), if it's shown.
  def card_contact = shown_links.find { it.key == card_link }
  def card_label = [ name, card_contact&.text ].compact.join(" · ")

  def logo_shown? = logo.attached? && Capabilities.enabled?("seller.logo", seller: self)
  def shown_logo_blob = (logo.blob if logo_shown?)

  # Fitted into an 800 px box at its own shape (D251) and stored as a PNG without metadata.
  def replace_logo!(upload)
    raise LogoRejected, "Choose a PNG, JPEG or WebP logo." unless LOGO_TYPES.include?(Marcel::MimeType.for(upload.tempfile))
    raise LogoRejected, "That logo is over #{LOGO_MAX_SIZE / 1.megabyte} MB." if upload.size > LOGO_MAX_SIZE

    image = Vips::Image.thumbnail(upload.tempfile.path, LOGO_BOX, height: LOGO_BOX, size: :down).colourspace(:srgb)
    image = (image / 257).cast(:uchar) if image.format == :ushort
    logo.attach(io: StringIO.new(image.write_to_buffer(".png", strip: true)), filename: "logo.png", content_type: "image/png")
  rescue Vips::Error
    raise LogoRejected, "That file couldn't be read as an image."
  end
end
