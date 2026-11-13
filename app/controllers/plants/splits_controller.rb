# Splitting a record that holds several plants into linked records (PL06, D133).
class Plants::SplitsController < ApplicationController
  include PlantScoped

  def new
    return redirect_to(@plant, alert: "Only a record with more than 1 plant can be split.") unless @plant.quantity.to_i > 1

    @schedules = @plant.care_schedules.running.order(:created_at) if capability?("care.reminders")
  end

  def create
    copies = capability?("care.reminders") ? @plant.care_schedules.running.where(id: Array(params[:copy_schedule_ids])).to_a : []
    created = @plant.split!(Array(params[:quantities]), copy_schedules: copies)
    redirect_to @plant, notice: "Split into #{created.map(&:record_id).to_sentence}. #{@plant.quantity} kept here."
  rescue Plant::TissueCulture::SplitRefused => error
    redirect_to new_plant_split_path(@plant), alert: error.message
  end
end
