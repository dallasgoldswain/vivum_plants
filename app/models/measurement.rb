# A dated reading of an environment's conditions: several values taken at one time from one
# source (EN02, D90). The client's idempotency key makes retries and offline syncs safe.
class Measurement < ApplicationRecord
  LAND = %w[ room_shelf grow_cabinet terrarium paludarium acclimatisation outdoor_bed ].freeze
  WATER = %w[ aquarium paludarium ].freeze

  # Fixed metrics in metric units; which ones a form offers depends on the environment type.
  # `range` catches typing slips (a humidity of 650) rather than judging the conditions.
  METRICS = {
    "air_temperature" => { label: "Air temperature", unit: "°C", range: -30..60, kinds: LAND },
    "humidity" => { label: "Humidity", unit: "%", range: 0..100, kinds: LAND },
    "water_temperature" => { label: "Water temperature", unit: "°C", range: 0..45, kinds: WATER },
    "ph" => { label: "pH", unit: "pH", range: 0..14, kinds: WATER },
    "gh" => { label: "General hardness (GH)", unit: "°dH", range: 0..60, kinds: WATER },
    "kh" => { label: "Carbonate hardness (KH)", unit: "°dH", range: 0..60, kinds: WATER },
    "light_hours" => { label: "Light hours per day", unit: "h", range: 0..24, kinds: Environment::KINDS },
    "light_lux" => { label: "Light intensity", unit: "lux", range: 0..200_000, kinds: Environment::KINDS },
    "light_ppfd" => { label: "PPFD", unit: "µmol/m²/s", range: 0..3_000, kinds: Environment::KINDS },
    "co2_note" => { label: "CO2 note", unit: "note", text: true, kinds: WATER }
  }.freeze

  CUSTOM = "custom".freeze

  belongs_to :user
  belongs_to :environment
  has_many :values, class_name: "MeasurementValue", dependent: :delete_all, inverse_of: :measurement

  normalizes :source, with: ->(value) { value.squish.presence || "Manual" }
  normalizes :note, with: ->(value) { value.squish.presence }

  validates :measured_at, :idempotency_key, presence: true
  validates :idempotency_key, length: { maximum: 64 }, uniqueness: { scope: :user_id }
  validates :source, length: { maximum: 80 }
  validates :note, length: { maximum: 500 }
  validate :has_values
  validate :not_in_the_future
  validate :same_owner

  scope :newest_first, -> { order(measured_at: :desc, id: :desc) }

  def self.metrics_for(environment) = METRICS.select { |_, metric| metric[:kinds].include?(environment.kind) }

  # Takes the form's fixed values ({ "humidity" => "80" }) and custom values
  # ({ custom_metric_id => "420" }, or new ones as [{ name:, unit:, value: }]). Blanks are
  # skipped; anything that isn't a number in range is reported against its label.
  def assign_readings(fixed: {}, custom: {}, new_custom: [])
    fixed.to_h.each do |key, raw|
      next if raw.to_s.strip.empty? || !(metric = METRICS[key.to_s])

      if metric[:text]
        values.build(metric: key, text_value: raw.to_s.squish.first(200), unit: metric[:unit])
      elsif (number = parse(raw, metric[:label], metric[:range]))
        values.build(metric: key, value: number, unit: metric[:unit])
      end
    end

    custom.to_h.each do |id, raw|
      next if raw.to_s.strip.empty? || !(custom_metric = user.custom_metrics.find_by(id: id))
      if (number = parse(raw, custom_metric.name))
        values.build(metric: CUSTOM, custom_metric: custom_metric, value: number, unit: custom_metric.unit)
      end
    end

    Array(new_custom).each do |entry|
      entry = entry.to_h.symbolize_keys
      next if entry[:value].to_s.strip.empty? && entry[:name].to_s.strip.empty?

      name, unit = entry[:name].to_s.squish, entry[:unit].to_s.squish
      next reading_errors << "Give your own reading a name and unit" if name.empty? || unit.empty?

      custom_metric = user.custom_metrics.where("lower(name) = ?", name.downcase).first || user.custom_metrics.build(name: name, unit: unit)
      if (number = parse(entry[:value], name))
        values.build(metric: CUSTOM, custom_metric: custom_metric, value: number, unit: custom_metric.unit)
      end
    end
  end

  private
    def reading_errors = (@reading_errors ||= [])

    def parse(raw, label, range = nil)
      number = BigDecimal(raw.to_s.strip.tr(",", "."))
      return number if range.nil? || range.cover?(number)

      reading_errors << "#{label} must be between #{range.min} and #{range.max}"
      nil
    rescue ArgumentError, TypeError
      reading_errors << "#{label} must be a number"
      nil
    end

    def has_values
      reading_errors.each { errors.add(:base, it) }
      errors.add(:base, "Enter at least one value") if values.empty? && reading_errors.empty?
      values.group_by { [ it.metric, it.custom_metric ] }.each_value do |same|
        errors.add(:base, "#{same.first.label} is entered twice") if same.many?
      end
    end

    def not_in_the_future
      errors.add(:measured_at, "can't be in the future") if measured_at && measured_at > 5.minutes.from_now
    end

    def same_owner
      errors.add(:environment, "must be yours") if environment && environment.user_id != user_id
    end
end
