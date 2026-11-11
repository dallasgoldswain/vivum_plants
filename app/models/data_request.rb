# A data subject request and its outcome (PRD PR05, D72). Exports and deletions are logged
# here by the self-service flows; access, correction, objection and other requests come from
# the form on Settings → Privacy and are worked by operators in Madmin.
class DataRequest < ApplicationRecord
  RESPONSE_TIME = 30.days # O13: confirm with the attorney
  EXPORT_TTL = 7.days # D68: how long an export can be downloaded
  FORM_KINDS = %w[ access correction objection other ].freeze
  CLOSED_STATUSES = %w[ completed declined cancelled ].freeze

  enum :kind, { export: "export", deletion: "deletion", access: "access", correction: "correction", objection: "objection", other: "other" }, validate: true
  enum :status, { open: "open", completed: "completed", declined: "declined", cancelled: "cancelled" }, validate: true

  belongs_to :user
  belongs_to :handled_by, class_name: "User", optional: true
  has_one_attached :export_file # served only through Settings::ExportsController, never a public URL

  validates :message, presence: true, length: { maximum: 5_000 }, if: -> { kind.in?(FORM_KINDS) }
  validates :outcome, presence: true, if: -> { completed? || declined? }, on: :update
  validate :one_export_at_a_time, on: :create

  before_validation -> { self.due_on ||= RESPONSE_TIME.from_now.to_date }, on: :create
  before_save -> { self.completed_at = (Time.current if status.in?(CLOSED_STATUSES)) }, if: :will_save_change_to_status?
  after_create -> { Audit.record("data_request.created", actor: Current.user || user, target: self, details: { kind: kind }) }
  after_update -> { Audit.record("data_request.#{status}", target: self, details: { kind: kind }) }, if: :saved_change_to_status?

  # The download link in the export email; it stops working once a newer export replaces it.
  generates_token_for :download, expires_in: EXPORT_TTL do
    completed_at
  end

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :overdue, -> { open.where(due_on: ...Date.current) }
  scope :exports_to_expire, -> { export.where(completed_at: ...EXPORT_TTL.ago).joins(:export_file_attachment) }

  def self.find_by_download_token(token) = find_by_token_for(:download, token)

  def self.expire_exports!
    exports_to_expire.find_each { it.export_file.purge }
  end

  def download_token = generate_token_for(:download)

  def downloadable?
    export? && completed? && export_file.attached? && completed_at > EXPORT_TTL.ago
  end

  def overdue? = open? && due_on.past?

  def close!(status, outcome:, by: nil)
    update!(status: status, outcome: outcome, handled_by: by)
  end

  private
    def one_export_at_a_time
      if export? && user && DataRequest.export.open.where(user: user).exists?
        errors.add(:base, "An export is already being prepared.")
      end
    end
end
