# A reading a collector adds for themselves, with its own name and unit, e.g. TDS in ppm (D90).
class CustomMetric < ApplicationRecord
  belongs_to :user
  has_many :measurement_values, dependent: :destroy

  normalizes :name, :unit, with: ->(value) { value.squish.presence }

  validates :name, presence: true, length: { maximum: 40 }, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :unit, presence: true, length: { maximum: 20 }

  scope :by_name, -> { order(Arel.sql("lower(name)")) }
end
