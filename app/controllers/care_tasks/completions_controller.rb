# "Done with details…" (D113): the quick care entry form for one task.
class CareTasks::CompletionsController < ApplicationController
  include CareTaskScoped
  include CareEntry

  def new
    return redirect_to(root_path, notice: "That's already done.") unless @care_task.open?

    @care_event = CareEvent.new(kind: @care_task.kind, label: @care_task.label, plant: @care_task.plant)
    @suggestions = CareEvent.suggestions_for(Current.user)
  end

  def create
    details = care_entry_params.slice(:note, *CareEvent::DETAIL_COLUMNS).to_h.symbolize_keys.transform_values(&:presence).except(:label)
    @care_task.complete!(idempotency_key: care_entry_key, occurred_at: care_entry_time, **details)
    respond_done "#{helpers.care_task_title(@care_task)}: done for #{@care_task.plant.display_name}."
  rescue ActiveRecord::RecordInvalid => error
    respond_refused(error.record.errors.full_messages, back: new_care_task_completion_path(@care_task))
  end
end
