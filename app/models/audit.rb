# Records audit events (D49–D52). Request details (IP, user agent, request id) and the
# actor come from Current unless given. Secrets (passwords, digests, TOTP secrets, codes,
# tokens, keys) are stripped from details with the audit log's own fixed list, so other
# log filtering can't change what is kept. Email addresses are kept (e.g. the address
# tried in a failed sign-in).
#
#   Audit.record("session.created", target: user)
#   Audit.record("madmin.update", target: record, details: { changes: record.saved_changes })
#   Audit.record("flag.enable", target_key: "seller.stock", details: { gate: "boolean" })
module Audit
  SECRET_PATTERNS = %i[ passw secret token _key crypt salt certificate otp code digest ssn cvv cvc ].freeze
  FILTER = ActiveSupport::ParameterFilter.new(SECRET_PATTERNS)

  def self.record(action, actor: Current.user, target: nil, target_key: nil, details: {}, reason: nil)
    AuditEvent.create!(
      action: action,
      actor_id: actor&.id,
      actor_email: actor&.email_address,
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
end
