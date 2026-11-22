require "csv"

# Sell → Orders (SE05, D179–D187): owners and managers create orders for a buyer, add lines,
# reserve, fulfil or cancel them. Lines and stock change through the order's own actions.
class Sell::OrdersController < Sell::BaseController
  requires_capability "seller.orders"
  before_action :set_order, only: %i[ show update ]

  FILTERS = { "open" => Order::OPEN_STATES, "review" => Order::STATES, "draft" => %w[ draft ], "reserved" => %w[ reserved ], "fulfilled" => %w[ fulfilled ], "cancelled" => %w[ cancelled ], "all" => Order::STATES }.freeze

  def index
    authorize! Order
    orders = authorized_scope(Order.all)
    respond_to do |format|
      format.html do
        @filter = FILTERS.key?(params[:filter]) ? params[:filter] : "open"
        @orders = orders.where(state: FILTERS[@filter]).search(params[:q]).includes(:lines, :payments).newest_first.limit(200)
        @orders = @orders.needing_review if @filter == "review"
      end
      format.csv do
        kind = %w[ lines payments documents returns ].include?(params[:kind]) ? params[:kind] : "orders"
        send_data send("#{kind}_csv", orders), filename: "#{kind == 'orders' ? 'orders' : "order-#{kind}"}-#{Date.current.iso8601}.csv", type: "text/csv"
      end
    end
  end

  def show
    @items = Current.seller.stock_items.active.includes(:balances, :listings).by_name
    @locations = Current.seller.stock_locations.where(archived_at: nil).order(:name)
    @addresses = @order.buyer.deleted? ? [] : @order.buyer.addresses
  end

  def new
    authorize! Order, to: :create?
    @order = Current.seller.orders.new(buyer_id: params[:buyer_id])
    @buyers = buyer_choices
  end

  def create
    authorize! Order, to: :create?
    @order = Current.seller.orders.new(params.expect(order: %i[ source notes ]))
    @order.buyer = Current.seller.buyers.active.find_by(id: params.dig(:order, :buyer_id))
    @order.created_by = Current.user
    if @order.save
      Audit.record("order.created", target: @order)
      redirect_to sell_order_path(@order), notice: "#{@order.reference} started for #{@order.buyer_name}."
    else
      @buyers = buyer_choices
      render :new, status: :unprocessable_entity
    end
  end

  # Source, notes, delivery, shipping fee and discount while the order is open (D182, D186).
  def update
    return redirect_to(sell_order_path(@order), alert: "This order is #{@order.state}; it can't change.") unless @order.open?
    return redirect_to(sell_order_path(@order), alert: "#{@order.receipt.reference} has been issued, so the order is fixed.") if @order.receipted?

    Order.transaction do
      @order.assign_attributes(params.expect(order: %i[ source notes delivery_method shipping discount discount_reason ]))
      address = @order.buyer.addresses.find_by(id: params.dig(:order, :address_id)) if @order.shipping?
      address ? @order.ship_to!(address) : @order.save!
    end
    redirect_to sell_order_path(@order), notice: "Saved."
  rescue ActiveRecord::RecordInvalid
    redirect_to sell_order_path(@order), alert: @order.errors.full_messages.to_sentence
  end

  private
    def set_order
      @order = authorized_scope(Order.all).includes(:documents, payments: :credit_note, lines: [ :stock_item, { stock_hold: :stock_location }, { returns: :stock_location } ]).find(params[:id])
      authorize! @order
    end

    def buyer_choices = Current.seller.buyers.active.by_name

    def orders_csv(orders)
      CSV.generate do |csv|
        csv << %w[ number buyer source state payment_state delivery_method shipping_address lines shipping discount discount_reason total paid currency created_at fulfilled_at cancelled_at cancel_reason ]
        orders.includes(:lines, :payments).order(:number).each do |order|
          csv << [ order.reference, order.buyer_name, order.source, order.state, order.payment_state, order.delivery_method, order.shipping_lines.join(", ").presence, order.lines_cents / 100.0, order.shipping, order.discount, order.discount_reason,
                   order.total_cents / 100.0, order.paid_cents / 100.0, order.currency, order.created_at.iso8601, order.fulfilled_at&.iso8601, order.cancelled_at&.iso8601, order.cancel_reason ]
        end
      end
    end

    def payments_csv(orders)
      CSV.generate do |csv|
        csv << %w[ number kind amount method paid_on reference reason recorded_by voided_at void_reason ]
        OrderPayment.where(order: orders).includes(:order, :recorded_by).order("orders.number", :id).references(:order).each do |payment|
          csv << [ payment.order.reference, payment.kind, payment.amount_cents / 100.0, payment.method, payment.paid_on.iso8601, payment.reference, payment.reason, payment.recorded_by&.email_address, payment.voided_at&.iso8601, payment.void_reason ]
        end
      end
    end

    def documents_csv(orders)
      CSV.generate do |csv|
        csv << %w[ reference kind order total vat_rate vat issued_at reason ]
        OrderDocument.where(order: orders).includes(:order).order(:number).each do |document|
          csv << [ document.reference, document.kind, document.order.reference, document.total_cents / 100.0, document.vat_rate&.to_s, document.vat_cents && document.vat_cents / 100.0, document.issued_at.iso8601, document.reason ]
        end
      end
    end

    def returns_csv(orders)
      CSV.generate do |csv|
        csv << %w[ number code quantity location outcome reason member created_at ]
        OrderReturn.joins(:order_line).where(order_lines: { order_id: orders.select(:id) }).includes(:stock_location, :member, order_line: [ :order, :stock_item ]).order(:created_at).each do |returned|
          csv << [ returned.order_line.order.reference, returned.order_line.stock_item.code, returned.quantity, returned.stock_location.name, returned.outcome, returned.reason, returned.member&.email_address, returned.created_at.iso8601 ]
        end
      end
    end

    def lines_csv(orders)
      CSV.generate do |csv|
        csv << %w[ number code description quantity agreed_price unit_price price_reason state cancel_reason ]
        OrderLine.where(order: orders).includes(:order, :stock_item).order("orders.number", :id).references(:order).each do |line|
          csv << [ line.order.reference, line.stock_item.code, line.description, line.quantity, line.agreed_price_cents / 100.0, line.unit_price_cents / 100.0, line.price_reason, line.state, line.cancel_reason ]
        end
      end
    end
end
