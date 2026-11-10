# Audit log (D49–D52): read-only for operators. Viewing it is itself audited.
class AuditEventResource < Madmin::Resource
  attribute :id, form: false
  attribute :created_at, form: false
  attribute :action, index: true
  attribute :actor_email, index: true
  attribute :actor, index: false
  attribute :target_type, index: true
  attribute :target_id, index: true
  attribute :target_key, index: true
  attribute :details, index: false
  attribute :reason, index: false
  attribute :ip_address, index: true
  attribute :user_agent, index: false
  attribute :request_id, index: false

  def self.readonly? = true
  def self.default_sort_column = "created_at"
  def self.default_sort_direction = "desc"
  def self.display_name(record) = "#{record.action} · #{record.created_at.to_fs(:db)}"
end
