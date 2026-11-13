module TissueCultureHelper
  TC_STAGE_LABELS = { "sealed" => "Sealed on arrival", "deflasked" => "Deflasked", "acclimatising" => "Acclimatising", "established" => "Established" }.freeze
  CONTAINER_CONDITION_LABELS = {
    "intact" => "Intact", "condensation" => "Heavy condensation", "cloudy" => "Cloudy or fuzzy growth", "leaking" => "Leaking",
    "damaged" => "Damaged", "dried_out" => "Dried out"
  }.freeze
  # What a check noticed, worded as observations, never a diagnosis (TC03).
  TC_CHECK_LABELS = { new_leaves: "New leaves", new_roots: "New roots", damage: "Damage", suspected_contamination: "Suspected contamination" }.freeze

  def tc_stage_label(stage) = TC_STAGE_LABELS.fetch(stage)
  def tc_stage_options = TC_STAGE_LABELS.map { |value, label| [ label, value ] }
  def container_condition_options = CONTAINER_CONDITION_LABELS.map { |value, label| [ label, value ] }

  # "New roots · Suspected contamination · Humidity: lid cracked"
  def tc_check_details(event)
    ticks = TC_CHECK_LABELS.filter_map { |column, label| label if event.public_send(column) }
    (ticks + [ ("Humidity: #{event.humidity_setup}" if event.humidity_setup) ]).compact.join(" · ").presence
  end

  # "Sealed on arrival since 13 Nov"
  def tc_stage_summary(plant)
    return "No stage set" unless plant.tc_stage

    since = plant.tc_stage_since
    [ tc_stage_label(plant.tc_stage), ("since #{l(since, format: :long)}" if since) ].compact.join(" ")
  end
end
