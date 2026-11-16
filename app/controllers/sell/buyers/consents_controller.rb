# The seller records that a buyer agreed, or withdrew (D174).
class Sell::Buyers::ConsentsController < Sell::BaseController
  include BuyerScoped

  def create
    purpose = params[:purpose].presence_in(BuyerConsent::PURPOSES.keys) or return back_to_buyer(alert: "Choose what the buyer agreed to.")
    given_on = Date.parse(params[:given_on].to_s) rescue Date.current
    @buyer.record_consent!(purpose, granted: params[:granted] == "1", source: "seller", method: params[:method].to_s.squish.presence, given_at: [ given_on.in_time_zone.end_of_day, Time.current ].min, by: Current.user)
    back_to_buyer(notice: "Recorded.")
  rescue ActiveRecord::RecordInvalid => error
    back_to_buyer(alert: error.record.errors.full_messages.to_sentence)
  end
end
