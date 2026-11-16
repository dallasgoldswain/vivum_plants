# One buyer's data as JSON, for their data request (PR05, D177). Owners only.
class Sell::Buyers::ExportsController < Sell::BaseController
  include BuyerScoped
  requires_capability "privacy.buyer_dsr"

  def show
    authorize! @buyer, to: :export?
    Audit.record("buyer.exported", target: @buyer)
    send_data JSON.pretty_generate(@buyer.export_data), filename: "buyer-#{@buyer.id}-#{Date.current.iso8601}.json", type: "application/json"
  end
end
