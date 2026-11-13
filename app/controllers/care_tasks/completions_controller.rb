# "Done with details…" (D113): the quick care or maintenance form for one task.
class CareTasks::CompletionsController < ApplicationController
  include CareTaskScoped

  def new
    return redirect_to(root_path, notice: "That's already done.") unless @care_task.open?

    @event = event_class.new(kind: @care_task.kind, label: @care_task.label)
    @suggestions = event_class.suggestions_for(Current.user)
  end

  def create
    entry = params.fetch(event_class.model_name.param_key, {}).permit(:note, :occurred_at, :idempotency_key, *event_class::DETAIL_COLUMNS)
    details = entry.slice(:note, *event_class::DETAIL_COLUMNS).to_h.symbolize_keys.transform_values(&:presence).except(:label)
    key = entry[:idempotency_key].to_s.first(64).presence || SecureRandom.uuid
    @care_task.complete!(idempotency_key: key, occurred_at: time_from(entry[:occurred_at]), **details)
    respond_done "#{helpers.care_task_title(@care_task)}: done for #{helpers.subject_name(@care_task.subject)}."
  rescue ActiveRecord::RecordInvalid => error
    respond_refused(error.record.errors.full_messages, back: new_care_task_completion_path(@care_task))
  end

  private
    def event_class = @care_task.environment ? EnvironmentEvent : CareEvent

    def time_from(value)
      Time.zone.parse(value.to_s) || Time.current
    rescue ArgumentError
      Time.current
    end
end
