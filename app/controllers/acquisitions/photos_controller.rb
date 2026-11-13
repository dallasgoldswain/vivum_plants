# Photos of a TC purchase on arrival (TC01), counted in the same collector cap (OF03).
class Acquisitions::PhotosController < ApplicationController
  include PhotoManaging
  requires_capability "collection.tissue_culture"
  prepend_before_action :set_acquisition

  private
    def set_acquisition
      @acquisition = Current.user.acquisitions.purchase_groups.find(params[:acquisition_id])
      authorize! Plant, to: :index?
    end

    def photo_subject = @acquisition
end
