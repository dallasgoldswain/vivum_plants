# Plants offered for Quick Claim in a session, at a fixed price (LS04, D214).
class Sell::SaleSessions::ClaimItemsController < Sell::BaseController
  include SaleSessionScoped
  requires_capability "sales.quick_claim"
  before_action { authorize! @sale_session, to: :update? }

  def create
    item = Current.seller.stock_items.find_by(id: params[:stock_item_id])
    location = Current.seller.stock_locations.find_by(id: params[:stock_location_id])
    price = params[:price].present? ? Order.cents(params[:price]) : item&.price_cents
    @sale_session.add_claim_item!(stock_item: item, location: location, price_cents: price)
    back(notice: "#{item.name} is up for claims.")
  end

  def destroy
    claim_item = @sale_session.claim_items.find(params[:id])
    claim_item.remove!(member: Current.user)
    back(notice: "#{claim_item.stock_item.name} is off claims.")
  end
end
