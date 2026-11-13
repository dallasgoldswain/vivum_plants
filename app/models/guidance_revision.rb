# One saved version of a collector's guidance defaults (ST02, D137). Revisions are only ever
# added; the newest is the account's current defaults, and each plant keeps the one it copied.
class GuidanceRevision < ApplicationRecord
  belongs_to :user
  has_many :plants, dependent: :restrict_with_exception

  scope :newest_first, -> { order(number: :desc) }
end
