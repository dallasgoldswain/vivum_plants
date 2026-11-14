# What a linked profile suggests for one plant (GU03, D145, D152): its care notes and the
# reminders for the plant's growing context that still need a decision. A suggestion is
# settled when the plant has the same reminder at the same cadence, accepted or reviewed it
# since the profile's last edit, or dismissed it since then.
class LibraryProfile::PlantSuggestions
  Item = Data.define(:suggestion, :existing) do
    # The plant's reminder of this kind; accepting replaces it after the comparison.
    def replaces? = existing.present?
    # It came from the profile before an edit (D152).
    def updated? = existing&.origin == "library"
  end

  attr_reader :plant, :profile

  def initialize(plant, profile = plant.library_profile)
    @plant = plant
    @profile = profile
  end

  def context = plant.growing_context
  def notes = profile.notes_for(context)
  def suggestions = profile.suggestions_for(context)
  def covered? = profile.covers?(context)

  def pending
    @pending ||= begin
      running = plant.care_schedules.select(&:active?)
      dismissed = plant.library_dismissals.select { it.library_profile_id == profile.id && it.created_at >= edited_at }
      suggestions.filter_map do |suggestion|
        next if dismissed.any? { it.kind == suggestion.kind && (suggestion.kind != "custom" || it.label.to_s.casecmp?(suggestion.label.to_s)) }

        existing = running.find { suggestion.matches?(it) }
        next if existing && (suggestion.same_cadence?(existing) || reviewed_since_edit?(existing))

        Item.new(suggestion, existing)
      end
    end
  end

  def updated? = pending.any?(&:updated?)

  private
    def edited_at = profile.content_edited_at || profile.created_at

    def reviewed_since_edit?(schedule)
      schedule.origin == "library" && schedule.library_profile_id == profile.id && schedule.library_synced_at && schedule.library_synced_at >= edited_at
    end
end
