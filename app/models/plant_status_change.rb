# One entry in a plant's status history (PL03): what changed, from when, and why.
class PlantStatusChange < ApplicationRecord
  belongs_to :plant

  enum :status, Plant::STATUSES.index_by(&:itself), validate: true

  validates :effective_on, presence: true
  validates :reason, length: { maximum: 200 }
end
