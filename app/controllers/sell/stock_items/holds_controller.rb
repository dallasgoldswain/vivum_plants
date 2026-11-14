# Holds stock for someone until a set time (D159, SE06): no default expiry, availability
# checked under a lock, released, fulfilled or expired once.
class Sell::StockItems::HoldsController < Sell::BaseController
  include StockItemScoped
  requires_capability "seller.reservations", only: :create
  before_action { authorize! @stock_item, to: :manage_stock? }
  before_action :set_hold, only: %i[ release fulfil ]

  def create
    location = location_param or return back_to_item(alert: "Choose a location.")
    expires_at = Time.zone.parse(params[:expires_at].to_s) if params[:expires_at].present?
    ledger.hold!(quantity: params[:quantity].to_i, location: location, held_for: params[:held_for], expires_at: expires_at)
    back_to_item(notice: "Held.")
  rescue Stock::Ledger::Refused => error
    back_to_item(alert: error.message)
  rescue ActiveRecord::RecordInvalid => error
    back_to_item(alert: error.record.errors.full_messages.to_sentence)
  end

  def release
    ledger.release!(@hold)
    back_to_item(notice: "Hold released.")
  rescue Stock::Ledger::Refused => error
    back_to_item(alert: error.message)
  end

  def fulfil
    ledger.fulfil!(@hold)
    back_to_item(notice: "Fulfilled: #{@hold.quantity} left stock.")
  rescue Stock::Ledger::Refused => error
    back_to_item(alert: error.message)
  end

  private
    def set_hold = @hold = @stock_item.holds.find(params[:id])
end
