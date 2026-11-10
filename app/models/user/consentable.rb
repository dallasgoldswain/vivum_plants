# A user's consents, kept as an append-only history in consent_records.
module User::Consentable
  extend ActiveSupport::Concern

  included do
    has_many :consent_records, dependent: :delete_all

    # Sign-up form fields (RegistrationsController saves with context :registration).
    attribute :terms_acceptance, :boolean
    attribute :marketing_email_opt_in, :boolean, default: false
    validates :terms_acceptance, acceptance: { allow_nil: false, accept: true, message: "and the privacy notice must be accepted" }, on: :registration

    after_create :record_sign_up_consents, if: :terms_acceptance
  end

  # Latest record per purpose, keyed by purpose. Memoised per request; reset on change.
  def current_consents
    @current_consents ||= consent_records.latest_per_purpose.index_by(&:purpose)
  end

  def consented_to?(purpose)
    current_consents[purpose.to_s]&.in_force? || false
  end

  # Required purposes (terms, privacy) without a grant of the current version.
  def pending_required_consents
    ConsentRecord::REQUIRED.reject { consented_to?(it) }
  end

  def required_consents_accepted?
    pending_required_consents.empty?
  end

  def record_consent!(purpose, granted:, source:)
    definition = ConsentRecord.purpose(purpose)
    raise ArgumentError, "#{purpose} cannot be withdrawn; close the account instead" if definition.required && !granted

    consent_records.create!(purpose: definition.key, version: definition.version, granted: granted, source: source).tap do
      @current_consents = nil
    end
  end

  def accept_required_consents!(source:)
    transaction { pending_required_consents.each { record_consent!(it, granted: true, source: source) } }
  end

  def reload(*)
    @current_consents = nil
    super
  end

  private
    def record_sign_up_consents
      ConsentRecord::REQUIRED.each { record_consent!(it, granted: true, source: "sign_up") }
      record_consent!(:marketing_email, granted: true, source: "sign_up") if marketing_email_opt_in
    end
end
