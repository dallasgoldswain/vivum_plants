# Photos of an environment, counted in the same collector cap as plant photos (D94).
class Environments::PhotosController < ApplicationController
  include EnvironmentScoped
  include PhotoManaging

  private
    def photo_subject = @environment
end
