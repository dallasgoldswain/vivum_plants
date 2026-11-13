# A plant's reminders (CA02, D112).
class Plants::CareSchedulesController < ApplicationController
  include PlantScoped
  include SubjectSchedules

  private
    def schedule_subject = @plant
end
