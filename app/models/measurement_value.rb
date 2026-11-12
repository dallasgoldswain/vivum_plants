# One value in a reading, always with its unit (EN02). Blank values are never stored, so
# what wasn't measured stays unknown rather than zero.
class MeasurementValue < ApplicationRecord
  belongs_to :measurement
  belongs_to :custom_metric, optional: true

  validates :unit, presence: true
  validate :value_present

  def label = custom_metric ? custom_metric.name : Measurement::METRICS.fetch(metric)[:label]

  def display_value
    return text_value if text_value

    number = value.to_s("F").delete_suffix(".0")
    case unit
    when "pH" then number
    when "°C", "%" then "#{number}#{unit}"
    else "#{number} #{unit}"
    end
  end

  private
    def value_present
      errors.add(:value, "can't be blank") if value.nil? && text_value.blank?
    end
end
