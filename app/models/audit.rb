# Records audit events (D49–D53). Request details (IP, user agent, request id) and the
# actor come from Current unless given.
#
# Personal data is kept to what the log's security purpose needs (POPIA s10):
# - the actor is stored as an id only;
# - email addresses are never stored; use Audit.email_fingerprint to record a keyed
#   hash that can be matched against a known address but not reversed;
# - secrets (passwords, digests, TOTP secrets, codes, tokens, keys) are stripped from
#   details with the log's own fixed list, as a backstop.
#
#   Audit.record("session.created", target: user)
#   Audit.record("session.failed", actor: nil, details: { email_fingerprint: Audit.email_fingerprint(email) })
module Audit
  SECRET_PATTERNS = %i[ passw secret token _key crypt salt certificate otp code digest ssn cvv cvc ].freeze
  FILTER = ActiveSupport::ParameterFilter.new(SECRET_PATTERNS)

  def self.record(action, actor: Current.user, target: nil, target_key: nil, details: {}, reason: nil)
    AuditEvent.create!(
      action: action,
      actor_id: actor&.id,
      target_type: target&.class&.base_class&.name,
      target_id: target&.id,
      target_key: target_key,
      details: FILTER.filter(details.deep_stringify_keys),
      reason: reason,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      request_id: Current.request_id
    )
  end

  # Keyed SHA-256 of a normalised email. The same address always gives the same value,
  # so repeated attempts can be grouped and a known user's address can be looked up,
  # without the address itself being stored.
  def self.email_fingerprint(email)
    normalised = email.to_s.strip.downcase
    return if normalised.empty?

    OpenSSL::HMAC.hexdigest("SHA256", fingerprint_key, normalised)
  end

  def self.fingerprint_key
    @fingerprint_key ||= Rails.application.key_generator.generate_key("audit/email-fingerprint", 32)
  end
end
