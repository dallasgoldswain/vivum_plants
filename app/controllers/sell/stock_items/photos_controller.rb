# Photos of a stock item, counted against the seller's plan (D163). Owners and managers add
# and remove them.
class Sell::StockItems::PhotosController < Sell::BaseController
  include StockItemScoped
  before_action { authorize! @stock_item, to: :update? }

  def create
    uploads = Array(params.dig(:photo, :images)).compact_blank
    return back_to_photos(alert: "Choose a photo to add.") if uploads.empty?

    added, rejected = 0, []
    uploads.each do |upload|
      Photo.build_from_upload(upload, user: Current.user, stock_item: @stock_item, caption: params.dig(:photo, :caption)).save!
      added += 1
    rescue Photo::Rejected => error
      rejected << "#{upload.original_filename}: #{error.message}"
    end
    flash[:alert] = rejected.uniq.to_sentence if rejected.any?
    flash[:notice] = "#{helpers.pluralize(added, 'photo')} added." if added.positive?
    back_to_photos
  end

  def cover
    @stock_item.update!(cover_photo: @stock_item.photos.find(params[:id]))
    back_to_photos(notice: "Cover photo set.")
  end

  def destroy
    @stock_item.photos.find(params[:id]).destroy!
    back_to_photos(notice: "Photo deleted.")
  end

  private
    def back_to_photos(**flash) = redirect_to(sell_stock_item_path(@stock_item, anchor: "photos"), **flash)
end
