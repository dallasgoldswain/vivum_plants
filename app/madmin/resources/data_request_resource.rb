# Data subject requests (PR05, D72). Operators reply to the person directly and record the
# outcome here; closing a request stamps who handled it and when. Requests that arrive some
# other way (email, phone) are logged with New. Exports and deletions are logged and closed by
# the self-service flows.
class DataRequestResource < Madmin::Resource
  attribute :id, form: false
  attribute :user
  attribute :kind
  attribute :status, description: "Completed or declined needs an outcome."
  attribute :due_on, form: false
  attribute :message, index: false
  attribute :outcome, :text, index: false, description: "What was done, or why it was declined. The person sees this in Settings → Privacy."
  attribute :handled_by, form: false, index: false
  attribute :completed_at, form: false
  attribute :created_at, form: false

  scope :open
  scope :overdue

  def self.default_sort_column = "due_on"
  def self.default_sort_direction = "asc"
  def self.display_name(record) = "#{record.kind.humanize} request ##{record.id}"
end
