require "csv"

# Sale Closeout (SC01, SC02, D219–D227): owners and managers turn a session's wins and claims
# into orders, one per buyer, and follow them through payment. Host/packers can't open it.
class Sell::SaleSessions::CloseoutsController < Sell::BaseController
  include SaleSessionScoped
  requires_capability "seller.closeout"
  before_action { authorize! @sale_session, to: :update? }
  rescue_from Order::Reserving::Refused, with: :refused

  def show
    @closeout = @sale_session.closeout
    @view = SaleSession::Closeout::VIEWS.key?(params[:view]) ? params[:view] : "awaiting"
    respond_to do |format|
      format.html { @buyers = Current.seller.buyers.active.by_name if @view == "unresolved" }
      format.csv { send_data closeout_csv, filename: "closeout-#{@sale_session.name.parameterize}-#{@view}-#{Date.current.iso8601}.csv", type: "text/csv" }
    end
  end

  def create
    added = @sale_session.closeout.create_orders!(Current.user)
    back(notice: added.zero? ? "Every result for a known buyer is already on an order." : "#{helpers.pluralize(added, 'result')} added to orders.")
  end

  private
    def back(**flash) = redirect_to(sell_sale_session_closeout_path(@sale_session, view: params[:view].presence), **flash)

    def closeout_csv
      CSV.generate do |csv|
        csv << %w[ buyer order item quantity price_each line_total subtotal payment_state hold_expires_at ]
        @closeout.orders_for(@view).each do |order|
          order.active_lines.each do |line|
            csv << [ order.buyer_name, order.reference, line.description, line.quantity, line.unit_price_cents / 100.0, line.total_cents / 100.0, order.lines_cents / 100.0, order.payment_state, order.hold_expires_at&.iso8601 ]
          end
        end
        pending_rows.each do |result|
          csv << [ result.closeout_buyer&.name || result.holder_name, nil, result.closeout_label, result.quantity, result.closeout_unit_cents / 100.0, result.quantity * result.closeout_unit_cents / 100.0, nil, "not ordered", result.stock_hold.expires_at&.iso8601 ]
        end
      end
    end

    def pending_rows
      case @view
      when "awaiting" then @closeout.ready
      when "expiring" then @closeout.pending_expiring
      when "unresolved" then @closeout.unresolved.values.flatten
      when "backup" then @closeout.backup_offers
      else []
      end
    end
end
