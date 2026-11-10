# One grant or withdrawal of consent (PRD PR03, decisions D54–D57). Append-only: a change of
# mind is a new record, and the latest record per purpose is the user's current choice.
class ConsentRecord < ApplicationRecord
  # audience: everyone (required to use VIVUM), owners (required for seller owners) or
  # optional (the user chooses).
  Purpose = Data.define(:key, :version, :audience, :label, :description) do
    def required = audience != :optional
  end

  # Code-owned. Bump a version whenever the text the user agrees to changes: a grant of an
  # older version no longer counts, so everyone is asked again. Versions of the legal
  # documents are shown on their pages (app/views/legal).
  PURPOSES = [
    Purpose.new(key: "terms", version: "0.1", audience: :everyone,
      label: "Terms of use", description: "The rules for using VIVUM Plants."),
    Purpose.new(key: "privacy", version: "0.1", audience: :everyone,
      label: "Privacy notice", description: "What we collect, why, who processes it and your rights."),
    Purpose.new(key: "seller_terms", version: "0.1", audience: :owners,
      label: "Seller terms", description: "The terms for running a business on VIVUM, including how you and VIVUM handle your buyers' data."),
    Purpose.new(key: "marketing_email", version: "1", audience: :optional,
      label: "News and offers by email",
      description: "Occasional emails about new features and offers. Account and order emails are sent either way."),
    Purpose.new(key: "ai_processing", version: "1", audience: :optional,
      label: "AI assistance",
      description: "Send the plant details and messages you choose to our AI providers (Anthropic, OpenAI) for care suggestions and extraction. Without it, AI features stay off."),
    Purpose.new(key: "whatsapp_reminders", version: "1", audience: :optional,
      label: "WhatsApp reminders",
      description: "Care and order reminders by WhatsApp, sent through Meta.")
  ].index_by(&:key).freeze

  EVERYONE = PURPOSES.values.select { it.audience == :everyone }.map(&:key).freeze
  OWNERS = PURPOSES.values.select { it.audience == :owners }.map(&:key).freeze
  SOURCES = %w[ sign_up settings in_context re_acceptance invitation ].freeze

  belongs_to :user

  validates :purpose, inclusion: { in: PURPOSES.keys }
  validates :source, inclusion: { in: SOURCES }
  validates :version, presence: true
  validates :granted, inclusion: { in: [ true, false ] }

  before_validation :capture_request_context, on: :create

  scope :chronological, -> { order(:created_at, :id) }

  # The latest record for each purpose.
  scope :latest_per_purpose, -> { select("DISTINCT ON (purpose) *").order(:purpose, created_at: :desc, id: :desc) }

  def self.purpose(key) = PURPOSES.fetch(key.to_s)

  def readonly?
    persisted? || super
  end

  def purpose_definition = PURPOSES[purpose]

  # Counts only when granted for the version currently in force.
  def in_force?
    granted? && version == purpose_definition&.version
  end

  private
    def capture_request_context
      self.ip_address ||= Current.ip_address
      self.user_agent ||= Current.user_agent
    end
end
