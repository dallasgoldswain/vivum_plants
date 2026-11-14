# Library profiles and the suggestions they bring (GU01, GU03, D143–D153).
module LibraryHelper
  NOTE_LABELS = {
    "light" => "Light", "watering" => "Watering", "humidity" => "Humidity",
    "temperature" => "Temperature", "substrate" => "Substrate", "feeding" => "Feeding"
  }.freeze

  # "Water every 7 days", "Feed every month", "Flush with RO water every 2 weeks"
  def suggestion_title(suggestion)
    what = suggestion.kind == "custom" ? suggestion.label : CareHelper::CARE_BUTTONS.fetch(suggestion.kind)
    every = suggestion.interval == 1 ? "every #{suggestion.interval_unit}" : "every #{suggestion.interval} #{CareHelper::INTERVAL_UNIT_LABELS[suggestion.interval_unit]}"
    "#{what} #{every}"
  end

  # Where a plant's suggestions come from (D151).
  def library_source_label(profile)
    "Your profile: #{profile.botanical_name}, edited #{l(profile.content_edited_at.to_date, format: :long)}"
  end

  def library_profile_names(profile)
    [ profile.common_names.first, profile.family ].compact_blank.join(" · ").presence
  end

  def library_context_options = Plant::GROWING_CONTEXTS.map { [ growing_context_label(it), it ] }
end
