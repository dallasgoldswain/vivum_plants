# Moving a task to another date by hand (CA05): later schedule edits leave it alone (D118).
class CareTasksController < ApplicationController
  include CareTaskScoped

  def update
    date = Date.iso8601(params.dig(:care_task, :due_on).to_s)
    @care_task.move_to!(date)
    redirect_to plant_path(@care_task.plant, anchor: "reminders"), notice: "Moved to #{l(date, format: :long)}."
  rescue Date::Error
    redirect_to plant_path(@care_task.plant, anchor: "reminders"), alert: "Choose a date."
  end
end
