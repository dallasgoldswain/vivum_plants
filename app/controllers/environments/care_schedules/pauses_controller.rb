# Pausing and resuming an environment's reminder (D125).
class Environments::CareSchedules::PausesController < ApplicationController
  include EnvironmentScoped
  include SubjectSchedulePausing

  private
    def schedule_subject = @environment
end
