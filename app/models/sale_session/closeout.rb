# A session's results on their way to orders (SC01, D219–D227). Won lots and held claims
# not yet on an order are pending; those for an alias with no linked buyer wait as
# unresolved, and the rest become one order per buyer per session on Create orders.
class SaleSession::Closeout
  VIEWS = { "awaiting" => "Awaiting payment", "unresolved" => "Unresolved", "expiring" => "Expiring", "backup" => "Backup offers", "ready" => "Ready to pack", "completed" => "Completed" }.freeze
  EXPIRING_WITHIN = 24.hours

  attr_reader :session

  def initialize(session)
    @session = session
  end

  def lots = @lots ||= session.lots.won.includes(:stock_item, :stock_hold, :winner_buyer, :backup_buyer, { winner_alias: :buyer, backup_alias: :buyer }, order_lines: { order: :payments }).to_a
  def claims = @claims ||= session.claims.held.includes(:stock_hold, :buyer, { buyer_alias: :buyer }, { claim_item: :stock_item }, order_lines: { order: :payments }).to_a

  def pending = @pending ||= (lots + claims).select(&:closeout_pending?)
  def ready = pending.select(&:closeout_buyer)
  def unresolved = pending.reject(&:closeout_buyer).group_by(&:closeout_alias)
  def backup_offers = lots.select(&:offer_to_backup?)
  def orders = @orders ||= session.orders.where.not(state: "cancelled").includes(:payments, :receipt, lines: %i[ stock_hold stock_item ]).order(:number).to_a

  def awaiting = orders.select { it.open? && !it.fully_paid? }
  def expiring = awaiting.select { expiring?(it.hold_expires_at) }
  def pending_expiring = ready.select { expiring?(it.stock_hold.expires_at) }
  def ready_to_pack = orders.select { it.reserved? && it.fully_paid? }
  def completed = orders.select(&:fulfilled?)

  def orders_for(view)
    case view
    when "awaiting" then awaiting
    when "expiring" then expiring
    when "ready" then ready_to_pack
    when "completed" then completed
    else []
    end
  end

  def count(view)
    case view
    when "unresolved" then unresolved.size
    when "backup" then backup_offers.size
    when "awaiting" then awaiting.size + ready.size
    when "expiring" then expiring.size + pending_expiring.size
    else orders_for(view).size
    end
  end

  # One tap, any number of times (D219): each buyer's pending results join their unpaid
  # order for this session, or a new reserved one. Returns how many lines were added.
  def create_orders!(member)
    session.with_lock do
      fresh = SaleSession::Closeout.new(session)
      fresh.ready.group_by(&:closeout_buyer).sum do |buyer, results|
        order = session.open_order_for(buyer) || start_order!(buyer, results, member)
        results.each { order.add_sale_line!(it, member: member) }
        results.size
      end
    end
  end

  private
    def expiring?(time) = time.present? && time.future? && time <= EXPIRING_WITHIN.from_now

    def start_order!(buyer, results, member)
      order = session.seller.orders.create!(buyer: buyer, source: "live_sale", sale_session: session, state: "reserved", created_by: member,
                                            hold_expires_at: results.map { it.stock_hold.expires_at }.min)
      Audit.record("order.created", actor: member, target: order, details: { source: "live_sale", sale_session_id: session.id })
      order
    end
end
