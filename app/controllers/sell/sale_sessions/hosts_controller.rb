# Host View (LS02, LS04, D217): the phone screen for running a live session: the open lot,
# the next one up, Quick Claim and the waitlist.
class Sell::SaleSessions::HostsController < Sell::BaseController
  include SaleSessionScoped
  before_action { authorize! @sale_session, to: :host? }

  def show
    @lots = @sale_session.lots.includes(:stock_item)
    @open_lot = @lots.find(&:open?)
    @next_lot = @lots.find(&:queued?)
    @claim_items = @sale_session.claim_items.active.includes(:stock_item, :stock_location)
  end
end
