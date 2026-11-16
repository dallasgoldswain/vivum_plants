# One grant or withdrawal of a buyer's consent to this seller (PR03, PR04, D174). Append-only:
# the latest record per purpose is the current choice.
class BuyerConsent < ApplicationRecord
  Purpose = Data.define(:key, :version, :label, :description)

  PURPOSES = [
    Purpose.new(key: "whatsapp_messages", version: "1", label: "WhatsApp messages",
      description: "Messages about orders, holds and requests on WhatsApp."),
    Purpose.new(key: "marketing", version: "1", label: "News and offers",
      description: "News about new plants and offers from this business. You can stop these at any time.")
  ].index_by(&:key).freeze
  SOURCES = %w[ seller buyer ].freeze

  belongs_to :buyer
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :purpose, inclusion: { in: PURPOSES.keys }
  validates :source, inclusion: { in: SOURCES }
  validates :method, length: { maximum: 200 }
  validates :method, presence: { message: "can't be blank: say how the buyer agreed" }, if: -> { source == "seller" && granted? }
  validates :given_at, presence: true

  def self.purpose(key) = PURPOSES.fetch(key.to_s)

  def readonly? = persisted? || super
  def in_force? = granted? && version == PURPOSES[purpose]&.version
end
