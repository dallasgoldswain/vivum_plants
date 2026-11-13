# Pausing and resuming a plant's reminder (D119).
class Plants::CareSchedules::PausesController < ApplicationController
  include PlantScoped
  include SubjectSchedulePausing

  private
    def schedule_subject = @plant
end
