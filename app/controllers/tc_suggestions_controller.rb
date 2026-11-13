# The suggested reminders for a TC stage (TC04, D131), for one plant or a purchase group's
# plantlets. Each row can be ticked, its cadence edited, or skipped; nothing is added
# unless ticked. A plant that already has the same reminder is left out (D120).
class TcSuggestionsController < ApplicationController
  requires_capability "collection.tissue_culture"
  requires_capability "care.reminders"

  def new
    authorize! Plant, to: :index?
    @plants = plants
    @stage = params[:stage].presence_in(Plant::TC_STAGES)
    return redirect_to(plants_path) if @plants.empty? || @stage.nil?

    @suggestions = TissueCulture::Suggestions.for(@stage, @plants.first.growing_context)
    redirect_to(back_path) if @suggestions.empty?
  end

  def create
    authorize! Plant, to: :index?
    rows = params.fetch(:suggestions, {}).values.select { it[:add] == "1" }
    made = 0
    CareSchedule.transaction do
      plants.each do |plant|
        rows.each do |row|
          interval = row[:interval].presence&.to_i
          schedule = plant.care_schedules.new(user: Current.user, origin: "tc_stage", kind: row[:kind], label: row[:label].presence, note: row[:note].presence,
            interval: interval, interval_unit: (row[:interval_unit] if interval), mode: "after_completion", starts_on: date_param(row[:starts_on]))
          next if schedule.valid? && schedule.same_kind_for_subject.any?

          schedule.save!
          schedule.start!
          made += 1
        end
      end
    end
    redirect_to back_path, notice: made.zero? ? "No reminders added." : "#{helpers.pluralize(made, 'reminder')} added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to back_path, alert: error.record.errors.full_messages.to_sentence
  end

  private
    def plants
      authorized_scope(Plant.all).in_active_collection.where(id: Array(params[:plant_ids]).compact_blank).order(:number).to_a
    end

    def back_path
      list = plants
      list.one? ? plant_path(list.first, anchor: "reminders") : (list.first&.acquisition ? acquisition_path(list.first.acquisition) : plants_path)
    end
end
