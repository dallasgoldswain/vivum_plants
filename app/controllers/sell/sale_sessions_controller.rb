require "csv"

# Sell → Sessions (LS01, D209, D210, D218): owners and managers set up a live sale and follow
# its results; host/packers see the sessions they host and go straight to Host View.
class Sell::SaleSessionsController < Sell::BaseController
  requires_capability "sales.sessions"
  before_action :set_sale_session, only: %i[ show edit update ]

  def index
    authorize! SaleSession
    sessions = authorized_scope(SaleSession.all)
    respond_to do |format|
      format.html { @sale_sessions = sessions.includes(:host_member).newest_first.limit(100) }
      format.csv do
        authorize! SaleSession, to: :create?
        send_data results_csv(sessions), filename: "sale-results-#{Date.current.iso8601}.csv", type: "text/csv"
      end
    end
  end

  def show
    @lots = @sale_session.lots.includes(:stock_item, :stock_location, :stock_hold)
    @claim_items = @sale_session.claim_items.includes(:stock_item, :stock_location, claims: :stock_hold)
    @items = Current.seller.stock_items.active.by_name
    @locations = Current.seller.stock_locations.where(archived_at: nil).order(:name)
  end

  def new
    authorize! SaleSession, to: :create?
    @sale_session = SaleSession.prefill_for(Current.seller)
    @sale_session.host_member = Current.user
  end

  def create
    authorize! SaleSession, to: :create?
    @sale_session = Current.seller.sale_sessions.new(session_params.merge(created_by: Current.user))
    if @sale_session.save
      Audit.record("sale_session.created", target: @sale_session)
      redirect_to sell_sale_session_path(@sale_session), notice: "#{@sale_session.name} set up. Add lots or claim plants, then go live."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    return redirect_to(sell_sale_session_path(@sale_session), alert: "This session is closed.") if @sale_session.closed?

    if @sale_session.update(session_params)
      redirect_to sell_sale_session_path(@sale_session), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_sale_session
      @sale_session = authorized_scope(SaleSession.all).find(params[:id])
      authorize! @sale_session
    end

    def session_params
      params.expect(sale_session: %i[ name channel host_member_id starts_at closes_at payment_hours backup_hours ])
    end

    def results_csv(sessions)
      CSV.generate do |csv|
        csv << %w[ session kind lot code quantity state winner price backup backup_bid transferred payment_due recorded_at ]
        SaleLot.where(sale_session: sessions).where.not(state: "queued").includes(:sale_session, :stock_item).order(:sale_session_id, :number).each do |lot|
          csv << [ lot.sale_session.name, "lot", lot.number, lot.stock_item.code, lot.quantity, lot.state, lot.winner_name, lot.price_cents&./(100.0), lot.backup_name, lot.backup_bid_cents&./(100.0), lot.transferred_at&.iso8601, lot.payment_due_at&.iso8601, lot.resolved_at&.iso8601 ]
        end
        SaleClaim.joins(:claim_item).where(sale_claim_items: { sale_session_id: sessions.select(:id) }).includes(claim_item: %i[ sale_session stock_item ]).order(:id).each do |claim|
          csv << [ claim.sale_session.name, "claim", claim.position, claim.stock_item.code, claim.quantity, claim.state, claim.holder_name, claim.price_cents / 100.0, nil, nil, nil, claim.payment_due_at&.iso8601, claim.created_at.iso8601 ]
        end
      end
    end
end
