# Suggested reminders for a TC stage, by where the plantlet is going (TC04, D131). Code-owned
# and offered after a stage change; nothing is added unless the collector ticks it. Checks
# are inspections, so they never move a stage; "Check readiness for repotting" asks rather
# than records a repot.
module TissueCulture::Suggestions
  Suggestion = Data.define(:kind, :label, :interval, :interval_unit, :starts_in_days, :note) do
    def once? = interval.nil?
  end

  def self.row(kind, label: nil, every: nil, unit: "day", in_days: 0, note: nil)
    Suggestion.new(kind: kind, label: label, interval: every, interval_unit: (unit if every), starts_in_days: in_days, note: note)
  end

  HUMID = %w[ indoor terrarium paludarium ].freeze

  SETS = {
    "sealed" => ->(_context) {
      [ row("inspection", every: 3, note: "Look through the container for cloudiness or fuzz"),
        row("custom", label: "Plan deflasking", in_days: 7) ]
    },
    "deflasked" => ->(context) {
      case context
      when "aquatic"
        [ row("inspection", every: 3, note: "Look at new leaves and roots"),
          row("custom", label: "Check readiness to plant out", in_days: 21) ]
      when "outdoor"
        [ row("inspection", every: 2),
          row("custom", label: "Hardening off review", every: 1, unit: "week", in_days: 7) ]
      else
        [ row("inspection", every: 2, note: "Look for new growth and any soft or browning leaves"),
          row("custom", label: "Ventilation review", every: 1, unit: "week", in_days: 7),
          row("custom", label: "Check readiness for repotting", in_days: 28) ]
      end
    },
    "acclimatising" => ->(context) {
      if HUMID.include?(context)
        [ row("custom", label: "Humidity review", every: 1, unit: "week", in_days: 7),
          row("inspection", every: 1, unit: "week", in_days: 7),
          row("custom", label: "Check readiness for repotting", in_days: 21) ]
      else
        [ row("inspection", every: 1, unit: "week", in_days: 7) ]
      end
    },
    "established" => ->(_context) { [] }
  }.freeze

  def self.for(stage, context) = SETS.fetch(stage, ->(_) { [] }).call(context)
end
