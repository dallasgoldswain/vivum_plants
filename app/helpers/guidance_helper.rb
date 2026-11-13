# Guidance switches and where a plant's came from (ST01–ST04, D135–D140).
module GuidanceHelper
  GUIDANCE_STATUSES = {
    matches: "Matches your defaults",
    older: "From older defaults",
    changed: "Changed for this plant"
  }.freeze

  # The switches a collector can see: AI waits for the AI pilot and consent (D135).
  def guidance_switches
    switches = { library: "Library suggestions" }
    switches[:ai] = "AI suggestions" if capability?("care.ai_guidance")
    switches
  end

  def guidance_status_label(status) = GUIDANCE_STATUSES.fetch(status)
  def on_off(value) = value ? "On" : "Off"

  # What applying these defaults would change on a plant, e.g. ["Library suggestions: Off → On"].
  def guidance_changes(plant, defaults)
    guidance_switches.filter_map do |key, label|
      before = plant.public_send(:"guidance_#{key}")
      after = defaults.public_send(key)
      "#{label}: #{on_off(before)} → #{on_off(after)}" if before != after
    end
  end

  # Said until library suggestions exist (D135).
  def guidance_pending_note
    "Library suggestions arrive soon. Until then this switch changes nothing." unless capability?("care.library_guidance")
  end
end
