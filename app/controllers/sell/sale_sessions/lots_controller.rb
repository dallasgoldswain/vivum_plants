# Auction lots (LS02, LS03, D211–D213). Hosts open, win and pass lots; owners and managers
# line them up and settle missed payments: offer to the backup bidder, relist or return.
class Sell::SaleSessions::LotsController < Sell::BaseController
  include SaleSessionScoped
  requires_capability "sales.auctions"
  requires_capability "sales.backup_bidder", only: :transfer
  before_action :set_lot, except: :create
  before_action(only: %i[ open win pass ]) { authorize! @sale_session, to: :host? }
  before_action(except: %i[ open win pass ]) { authorize! @sale_session, to: :update? }

  def create
    item = Current.seller.stock_items.find_by(id: params[:stock_item_id])
    location = Current.seller.stock_locations.find_by(id: params[:stock_location_id])
    lot = @sale_session.add_lot!(stock_item: item, location: location, quantity: params[:quantity].presence || 1)
    back(notice: "#{lot.label} added: #{item.name}.")
  end

  def destroy
    return back(alert: "Only a lot that hasn't opened can be removed.") unless @lot.queued?

    @lot.destroy!
    back(notice: "#{@lot.label} removed.")
  end

  def open
    @lot.open!(member: Current.user)
    back(notice: "#{@lot.label} is open: #{@lot.stock_item.name}.")
  end

  def win
    @lot.win!(member: Current.user, winner: holder(:winner), price_cents: cents(:price), backup: holder(:backup), backup_bid_cents: cents(:backup_bid))
    back(notice: "#{@lot.label} won by #{@lot.winner_name}.")
  end

  def pass
    @lot.pass!(member: Current.user)
    back(notice: "#{@lot.label} passed.")
  end

  def transfer
    @lot.transfer_to_backup!(member: Current.user)
    back(notice: "#{@lot.label} offered to #{@lot.backup_name}.")
  end

  def relist
    lot = @lot.relist!(member: Current.user)
    back(notice: "Relisted as #{lot.label}.")
  end

  def return_stock
    @lot.return_to_stock!(member: Current.user)
    back(notice: "#{@lot.label} returned to stock.")
  end

  private
    def set_lot
      @lot = @sale_session.lots.find(params[:id])
    end

    def cents(key) = params[key].presence && Order.cents(params[key])
end
