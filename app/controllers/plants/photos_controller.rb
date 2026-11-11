# Photos added straight to a plant, captions, dates and the cover (PL04, OF03).
class Plants::PhotosController < ApplicationController
  include PlantScoped
  requires_capability "collection.media"
  before_action :set_photo, only: %i[ update destroy cover ]

  def create
    attributes = params.fetch(:photo, {}).permit(:caption, :taken_on, images: [])
    uploads = Array(attributes[:images]).compact_blank
    return redirect_to(plant_path(@plant, anchor: "photos"), alert: "Choose a photo to add.") if uploads.empty?

    added, rejected = 0, []
    uploads.each do |upload|
      Photo.build_from_upload(upload, user: Current.user, plant: @plant, caption: attributes[:caption], taken_on: attributes[:taken_on]).save!
      added += 1
    rescue Photo::Rejected => error
      rejected << "#{upload.original_filename}: #{error.message}"
    end

    flash[:alert] = rejected.uniq.to_sentence if rejected.any?
    flash[:notice] = "#{helpers.pluralize(added, 'photo')} added." if added.positive?
    redirect_to plant_path(@plant, anchor: "photos")
  end

  def update
    if @photo.update(params.expect(photo: %i[ caption taken_on ]))
      redirect_to plant_path(@plant, anchor: "photos"), notice: "Photo saved."
    else
      redirect_to plant_path(@plant, anchor: "photos"), alert: @photo.errors.full_messages.to_sentence
    end
  end

  def cover
    @plant.update!(cover_photo: @photo)
    redirect_to plant_path(@plant, anchor: "photos"), notice: "Cover photo set."
  end

  def destroy
    @photo.destroy!
    redirect_to plant_path(@plant, anchor: "photos"), notice: "Photo deleted."
  end

  private
    def set_photo
      @photo = @plant.photos.find(params[:id])
    end
end
