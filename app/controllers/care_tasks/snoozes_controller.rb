# Snooze hides a task from Today until a day; its due date stays (CA03, D116).
class CareTasks::SnoozesController < ApplicationController
  include CareTaskScoped

  def create
    until_date =
      case params[:until]
      when "tomorrow" then Date.current + 1
      when "3" then Date.current + 3
      else date_or_nil(params[:until_date])
      end
    if until_date && @care_task.update(snoozed_until: until_date)
      respond_done "Snoozed until #{l(until_date, format: :long)}."
    else
      respond_refused([ "Choose a day after today." ])
    end
  end

  private
    def date_or_nil(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
end
