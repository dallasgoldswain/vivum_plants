# Photos added straight to a plant or an environment: upload, caption and date, cover and
# delete (PL04, OF03, D94). The including controller names the subject and where to return.
module PhotoManaging
  extend ActiveSupport::Concern

  included do
    requires_capability "collection.media"
    before_action :set_photo, only: %i[ update destroy cover ]
  end

  def create
    attributes = params.fetch(:photo, {}).permit(:caption, :taken_on, images: [])
    uploads = Array(attributes[:images]).compact_blank
    return redirect_to(photos_return_path, alert: "Choose a photo to add.") if uploads.empty?

    added, rejected = 0, []
    uploads.each do |upload|
      Photo.build_from_upload(upload, user: Current.user, photo_subject.model_name.element.to_sym => photo_subject, caption: attributes[:caption], taken_on: attributes[:taken_on]).save!
      added += 1
    rescue Photo::Rejected => error
      rejected << "#{upload.original_filename}: #{error.message}"
    end

    flash[:alert] = rejected.uniq.to_sentence if rejected.any?
    flash[:notice] = "#{helpers.pluralize(added, 'photo')} added." if added.positive?
    redirect_to photos_return_path
  end

  def update
    if @photo.update(params.expect(photo: %i[ caption taken_on ]))
      redirect_to photos_return_path, notice: "Photo saved."
    else
      redirect_to photos_return_path, alert: @photo.errors.full_messages.to_sentence
    end
  end

  def cover
    photo_subject.update!(cover_photo: @photo)
    redirect_to photos_return_path, notice: "Cover photo set."
  end

  def destroy
    @photo.destroy!
    redirect_to photos_return_path, notice: "Photo deleted."
  end

  private
    def set_photo
      @photo = photo_subject.photos.find(params[:id])
    end

    def photos_return_path = polymorphic_path(photo_subject, anchor: "photos")
end
