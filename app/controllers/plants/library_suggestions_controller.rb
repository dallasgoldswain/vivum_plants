# Accepts one suggested reminder, as suggested or edited (GU03, D145). Where the plant has a
# reminder of that kind, the comparison was shown first and the old one ends, keeping its
# history. Nothing changes until this is posted.
class Plants::LibrarySuggestionsController < ApplicationController
  include PlantScoped
  requires_capability "care.library_guidance"

  def create
    suggestions = @plant.library_suggestions or return redirect_back_to_guidance(alert: "Turn on library suggestions for this plant first.")
    item = suggestions.pending.find { it.suggestion.kind == params[:kind] && it.suggestion.label.to_s == params[:label].to_s } or
      return redirect_back_to_guidance(alert: "That suggestion has already been dealt with.")

    interval = params[:interval].presence&.to_i || item.suggestion.interval
    unit = params[:interval_unit].presence_in(CareSchedule::INTERVAL_UNITS) || item.suggestion.interval_unit
    CareSchedule.transaction do
      item.existing&.end!
      @plant.care_schedules.create!(user: Current.user, kind: item.suggestion.kind, label: item.suggestion.label, interval: interval, interval_unit: unit,
        mode: "after_completion", starts_on: Date.current, origin: "library", library_profile: suggestions.profile, library_synced_at: Time.current).start!
    end
    redirect_back_to_guidance(notice: "Reminder added: #{helpers.suggestion_title(item.suggestion.with(interval: interval, interval_unit: unit))}.")
  rescue ActiveRecord::RecordInvalid => error
    redirect_back_to_guidance(alert: error.record.errors.full_messages.to_sentence)
  end

  private
    def redirect_back_to_guidance(**flash)
      redirect_to plant_path(@plant, anchor: "guidance"), **flash
    end
end
