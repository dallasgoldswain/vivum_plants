# The same reminder for several plants at once, one schedule each (D112), from an environment
# or the collection's current filters. Plants that already have one are left out, kept as
# well, or replaced, as the collector chooses (D120).
class CareSchedulesController < ApplicationController
  include CareScheduleForm
  requires_capability "collection.plants"
  requires_capability "care.reminders"

  DUPLICATE_CHOICES = %w[ leave_out keep replace ].freeze

  def new
    authorize! Plant, to: :index?
    @environment = Current.user.environments.find(params[:environment_id]) if params[:environment_id].present?
    @plants = choosable_plants
    @selected = @environment ? @plants.map(&:id) : Array(params[:plant_ids]).map(&:to_i)
    @schedule = default_schedule(nil)
  end

  def create
    authorize! Plant, to: :index?
    plants = authorized_scope(Plant.all).in_active_collection.where(id: Array(params[:plant_ids]).compact_blank).order(:display_name).to_a
    return redirect_back_or_to(new_care_schedule_path, alert: "Choose at least one plant.") if plants.empty?

    choice = params[:duplicate].presence_in(DUPLICATE_CHOICES) || "leave_out"
    made = 0
    CareSchedule.transaction do
      plants.each do |plant|
        schedule = plant.care_schedules.new(user: Current.user, **schedule_attributes)
        schedule.validate!
        duplicates = schedule.same_kind_for_plant
        next if duplicates.any? && choice == "leave_out"

        duplicates.each(&:end!) if choice == "replace"
        schedule.save!
        schedule.start!
        made += 1
      end
    end
    redirect_to return_path, notice: "Reminder set for #{helpers.pluralize(made, 'plant')}#{" (#{plants.size - made} already had one)" if made < plants.size}."
  rescue ActiveRecord::RecordInvalid => error
    redirect_back_or_to new_care_schedule_path, alert: error.record.errors.full_messages.to_sentence
  end

  private
    def choosable_plants
      plants = authorized_scope(Plant.all).in_active_collection.order(:display_name, :number)
      return plants.where(id: EnvironmentAssignment.current.where(environment: @environment).select(:plant_id)) if @environment

      plants.search(params[:q]).filtered(context: params[:context], status: params[:status], tc_origin: params[:tc], tag: params[:tag], environment: params[:environment], unwatered_days: params[:unwatered])
    end

    def return_path
      environment = Current.user.environments.find_by(id: params[:environment_id]) if params[:environment_id].present?
      environment ? environment_path(environment) : plants_path
    end
end
