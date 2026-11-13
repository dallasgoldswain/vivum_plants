# An environment's reminders, such as a weekly water change (D125).
class Environments::CareSchedulesController < ApplicationController
  include EnvironmentScoped
  include SubjectSchedules

  private
    def schedule_subject = @environment
end
