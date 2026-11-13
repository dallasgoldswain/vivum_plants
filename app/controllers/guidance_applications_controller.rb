# Applies the current defaults to several plants chosen from the collection, with one summary
# of what changes (ST04, D140). Only switches and revisions change.
class GuidanceApplicationsController < ApplicationController
  requires_capability "collection.plants"
  requires_capability "care.guidance_settings"

  def new
    authorize! Plant, to: :index?
    @defaults = Current.user.guidance_defaults
    @plants = authorized_scope(Plant.all).includes(:guidance_revision).order(:display_name, :number)
      .search(params[:q]).filtered(context: params[:context], status: params[:status], tc_origin: params[:tc], tag: params[:tag], environment: params[:environment], unwatered_days: params[:unwatered])
    @behind = @plants.reject { it.guidance_status(@defaults) == :matches }.map(&:id)
  end

  def create
    authorize! Plant, to: :index?
    defaults = Current.user.guidance_defaults
    plants = authorized_scope(Plant.all).where(id: Array(params[:plant_ids]).compact_blank).to_a
    return redirect_to(new_guidance_application_path, alert: "Choose at least one plant.") if plants.empty?

    Plant.transaction { plants.each { it.apply_guidance_defaults!(defaults) } }
    redirect_to plants_path, notice: "Applied your current defaults to #{helpers.pluralize(plants.size, 'plant')}."
  end
end
