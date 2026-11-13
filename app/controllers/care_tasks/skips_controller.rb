# Skip logs no care and makes the next task (CA03).
class CareTasks::SkipsController < ApplicationController
  include CareTaskScoped

  def create
    @care_task.skip!
    respond_done "Skipped #{helpers.care_task_title(@care_task).downcase} for #{helpers.subject_name(@care_task.subject)}."
  end
end
