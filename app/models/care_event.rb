# An entry on a plant's timeline (D82). Observations come first; B13 adds watering, feeding,
# repotting and other kinds. The event date is when it happened, separate from when it was
# entered (PL04). The client's idempotency key makes retries and offline syncs safe (OF02).
class CareEvent < ApplicationRecord
  KINDS = %w[ observation ].freeze

  belongs_to :user
  belongs_to :plant
  has_many :photos, -> { order(:id) }, dependent: :destroy

  enum :kind, KINDS.index_by(&:itself), validate: true, default: "observation"

  validates :occurred_at, :idempotency_key, presence: true
  validates :idempotency_key, length: { maximum: 64 }, uniqueness: { scope: :user_id }
  validates :note, length: { maximum: 5000 }
  validate :note_or_photos
  validate :plant_belongs_to_user

  attr_accessor :photos_expected

  # Returns the event already saved with this key, if any, so a retry creates nothing.
  def self.record_once(user:, plant:, idempotency_key:, **attributes)
    user.care_events.find_by(idempotency_key: idempotency_key) ||
      user.care_events.create(plant: plant, idempotency_key: idempotency_key, **attributes)
  rescue ActiveRecord::RecordNotUnique
    user.care_events.find_by!(idempotency_key: idempotency_key)
  end

  private
    def note_or_photos
      errors.add(:note, "can't be blank without a photo") if note.blank? && !photos_expected
    end

    def plant_belongs_to_user
      errors.add(:plant, "must be yours") if plant && plant.user_id != user_id
    end
end
