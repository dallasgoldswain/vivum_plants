# Changing a plant's status with an effective date and reason (PL03).
class Plants::StatusChangesController < ApplicationController
  include PlantScoped

  def create
    attributes = params.expect(plant_status_change: %i[ status effective_on reason ])
    status = attributes[:status].to_s
    return redirect_to(@plant, alert: "Choose a status.") unless Plant.statuses.key?(status)

    @plant.change_status!(status, on: parse_date(attributes[:effective_on]), reason: attributes[:reason].to_s.first(200))
    message = @plant.active? ? "Status set to #{status.humanize.downcase}." : "Status set to #{status.humanize.downcase}. It's kept, with its history, under inactive plants."
    redirect_to @plant, notice: message
  end

  private
    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      Date.current
    end
end
