# Seller invites (SO03, D58–D62): operators enter an email and business name; staff invites
# made by owners are listed too. Invites can't be edited or deleted, only resent or revoked.
class InvitationResource < Madmin::Resource
  attribute :id, form: false
  attribute :kind, form: false
  attribute :email_address
  attribute :business_name
  attribute :role, form: false
  attribute :seller, form: false
  attribute :invited_by, form: false
  attribute :expires_at, form: false
  attribute :accepted_at, form: false
  attribute :accepted_by, form: false, index: false
  attribute :revoked_at, form: false
  attribute :created_at, form: false

  member_action do |invitation|
    if invitation.pending?
      # The link can be shared anywhere (e.g. WhatsApp): only the invited email can accept it.
      safe_join([
        text_field_tag(:invite_link, invitation_url(invitation.acceptance_token), readonly: true, autocomplete: "off", aria: { label: "Invite link" }, onclick: "this.select()", size: 40),
        button_to("Resend", resend_madmin_invitation_path(invitation), class: "btn btn-secondary"),
        button_to("Revoke", revoke_madmin_invitation_path(invitation), class: "btn btn-danger", data: { turbo_confirm: "Revoke this invite? Its link stops working." })
      ])
    end
  end

  def self.readonly_for?(record) = record&.persisted? || false
  def self.default_sort_column = "created_at"
  def self.default_sort_direction = "desc"
  def self.display_name(record) = "#{record.kind.humanize} invite · #{record.business_label}"
end
