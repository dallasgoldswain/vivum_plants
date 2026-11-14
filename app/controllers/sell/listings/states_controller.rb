# Puts a listing live, pauses it or ends it. Never changes stock (SE03, D165).
class Sell::Listings::StatesController < Sell::BaseController
  requires_capability "seller.listings"

  def update
    listing = authorized_scope(Listing.all).find(params[:listing_id])
    authorize! listing, to: :update?
    case params[:state]
    when "active" then listing.activate!
    when "paused" then listing.pause!
    when "ended" then listing.end!
    else return redirect_to(sell_listing_path(listing), alert: "Choose what to do.")
    end
    redirect_to sell_listing_path(listing), notice: "#{listing.reference} is #{listing.display_state}."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to sell_listing_path(listing), alert: error.record.errors.full_messages.to_sentence
  end
end
