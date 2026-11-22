require "test_helper"

class OrderPaymentsTest < ActionDispatch::IntegrationTest
  FLAGS = %w[ seller.workspace seller.members seller.stock seller.reservations seller.buyers seller.orders payments.manual seller.receipts seller.vat_invoices help.manual help.contextual ].freeze

  setup do
    FLAGS.each { Flipper.enable(it) }
    @seller = sellers(:fern_and_frond)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    @pothos = @seller.stock_items.create!(kind: "batch", name: "Pothos", price_cents: 20000)
    Stock::Ledger.new(@pothos, member: users(:owner)).receive!(quantity: 5, location: @greenhouse)
    @order = @seller.orders.create!(buyer: @buyer)
    @order.add_line!(item: @pothos, quantity: 2, member: users(:owner))
  end

  test "an owner records payments, opens the receipt and its PDF" do
    sign_in_as users(:owner)
    post sell_order_payments_path(@order), params: { amount: "200", method: "eft", paid_on: Date.current.iso8601, reference: "Sam EFT" }
    post sell_order_payments_path(@order), params: { amount: "R200", method: "cash", paid_on: Date.current.iso8601 }
    assert_equal "paid", @order.reload.payment_state

    get sell_order_path(@order)
    assert_select "#payments li[id^=order_payment]", 2
    assert_select "#documents a", text: "Receipt R-0001"
    get sell_order_document_path(@order, @order.receipt)
    assert_select "#document_total", "R400"
    assert_select "#document_vat", 0
    get sell_order_document_path(@order, @order.receipt, format: :pdf)
    assert_equal "application/pdf", response.media_type

    get sell_orders_path(format: :csv, kind: "payments")
    assert_match "O-0001,payment,200.0,eft", response.body
    get sell_orders_path(format: :csv, kind: "documents")
    assert_match "R-0001,receipt,O-0001,400.0", response.body
  end

  test "a refund needs a reason and can't exceed what's paid" do
    @order.record_payment!(amount_cents: 10000, method: "eft", paid_on: Date.current, member: users(:owner))
    sign_in_as users(:owner)
    post sell_order_payments_path(@order), params: { kind: "refund", amount: "150", method: "eft", paid_on: Date.current.iso8601, reason: "Too much" }
    assert_match "more than has been paid", flash[:alert]
    post sell_order_payments_path(@order), params: { kind: "refund", amount: "50", method: "eft", paid_on: Date.current.iso8601 }
    assert_match "Reason is needed", flash[:alert]
    assert_equal 10000, @order.reload.paid_cents
  end

  test "a host/packer can't record payments or open receipts (D198)" do
    sign_in_as users(:packer)
    post sell_order_payments_path(@order), params: { amount: "400", method: "cash", paid_on: Date.current.iso8601 }
    assert_redirected_to root_path
    assert_empty @order.payments
  end

  test "an owner sets business details; a VAT number needs 10 digits starting with 4 (D193)" do
    sign_in_as users(:owner)
    patch sell_business_details_path, params: { seller: { legal_name: "Fern & Frond (Pty) Ltd", vat_number: "123", address: "1 Oak St\nDurban" } }
    assert_response :unprocessable_entity
    assert_match "must be 10 digits starting with 4", response.body

    patch sell_business_details_path, params: { seller: { legal_name: "Fern & Frond (Pty) Ltd", vat_number: "4123 456 789", address: "1 Oak St\nDurban" } }
    assert_equal "4123456789", @seller.reload.vat_number

    sign_in_as users(:manager)
    patch current_seller_path, params: { seller_id: @seller.id }
    get edit_sell_business_details_path
    assert_redirected_to root_path
  end

  test "a return is recorded against a fulfilled order" do
    @order.reserve!(expires_at: 1.day.from_now, member: users(:owner))
    @order.fulfil!(member: users(:owner), unpaid_confirmed: true)
    sign_in_as users(:owner)
    post sell_order_returns_path(@order), params: { line_id: @order.lines.first.id, quantity: 1, stock_location_id: @greenhouse.id, outcome: "unavailable", reason: "Arrived damaged" }
    assert_equal "Return recorded.", flash[:notice]
    assert_equal [ 4, 1 ], @pothos.reload.totals.then { [ it.on_hand, it.unavailable ] }
  end
end
