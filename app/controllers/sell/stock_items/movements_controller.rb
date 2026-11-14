# Records one stock change from the item page (SE02, D157, D158, D160). Owners and managers
# receive and count; every member can move, mark unavailable or available, and record losses
# (D161).
class Sell::StockItems::MovementsController < Sell::BaseController
  include StockItemScoped

  MANAGER_KINDS = %w[ receipt count ].freeze
  KINDS = MANAGER_KINDS + %w[ move mark_unavailable mark_available loss ]

  def create
    kind = params[:kind].presence_in(KINDS) or return back_to_item(alert: "Choose what happened.")
    authorize! @stock_item, to: (MANAGER_KINDS.include?(kind) ? :manage_stock? : :handle?)

    quantity = params[:quantity].to_i
    location = location_param or return back_to_item(alert: "Choose a location.")
    reason = params[:reason].to_s.squish.presence
    case kind
    when "receipt" then ledger.receive!(quantity: quantity, location: location, reason: reason)
    when "move" then ledger.move!(quantity: quantity, from: location, to: location_param(:to_location_id) || (return back_to_item(alert: "Choose where it's going.")), bucket: params[:bucket].presence_in(StockMovement::BUCKETS) || "saleable", reason: reason)
    when "mark_unavailable" then ledger.mark_unavailable!(quantity: quantity, location: location, reason: reason || "Other")
    when "mark_available" then ledger.mark_available!(quantity: quantity, location: location, reason: reason)
    when "loss" then ledger.lose!(quantity: quantity, location: location, bucket: params[:bucket].presence_in(StockMovement::BUCKETS) || "saleable", reason: reason || "Lost")
    when "count" then ledger.count!(counted: params[:counted], location: location, reason: reason || "Count")
    end
    back_to_item(notice: "Stock updated.")
  rescue Stock::Ledger::Refused => error
    back_to_item(alert: error.message)
  end
end
