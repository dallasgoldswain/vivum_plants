# Dismisses one suggested reminder for this plant until the profile is next edited (D145).
# A reminder accepted from an earlier edit stays as it is (D152).
class Plants::LibraryDismissalsController < ApplicationController
  include PlantScoped
  requires_capability "care.library_guidance"

  def create
    suggestions = @plant.library_suggestions or return redirect_to(plant_path(@plant, anchor: "guidance"))
    item = suggestions.pending.find { it.suggestion.kind == params[:kind] && it.suggestion.label.to_s == params[:label].to_s }
    if item
      LibraryDismissal.transaction do
        Current.user.library_dismissals.create!(plant: @plant, library_profile: suggestions.profile, kind: item.suggestion.kind, label: item.suggestion.label)
        item.existing.update!(library_synced_at: Time.current) if item.updated?
      end
    end
    redirect_to plant_path(@plant, anchor: "guidance"), notice: "Suggestion dismissed."
  end
end
