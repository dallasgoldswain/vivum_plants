# Photos added straight to a plant, captions, dates and the cover (PL04, OF03).
class Plants::PhotosController < ApplicationController
  include PlantScoped
  include PhotoManaging

  private
    def photo_subject = @plant
end
