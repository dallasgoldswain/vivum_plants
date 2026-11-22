require "test_helper"

class OrderPaymentTest < ActiveSupport::TestCase
  setup do
    @seller = sellers(:fern_and_frond)
    @member = users(:manager)
    @greenhouse = @seller.stock_locations.create!(name: "Greenhouse")
    @buyer = @seller.buyers.create!(name: "Sam Dlamini", phone: "0821234567")
    @pothos = @seller.stock_items.create!(kind: "batch", name: "Pothos", price_cents: 20000)
    Stock::Ledger.new(@pothos, member: @member).receive!(quantity: 5, location: @greenhouse)
  end

  test "two payments make it paid and issue one receipt; voiding one keeps the receipt (D189, D191)" do
    order = order(2)
    pay(order, 20000)
    assert_equal "part_paid", order.reload.payment_state
    assert_nil order.receipt

    pay(order, 20000)
    receipt = order.reload.receipt
    assert_equal [ "paid", "R-0001", 40000, nil ], [ order.payment_state, receipt.reference, receipt.total_cents, receipt.vat_rate ]
    assert_equal 2, receipt.details["payments"].size

    order.void_payment!(order.payments.first, reason: "Bounced", member: @member)
    assert_equal "part_paid", order.reload.payment_state
    assert_equal [ receipt ], order.documents.to_a
    pay(order, 20000)
    assert_equal 1, order.reload.documents.count
  end

  test "a VAT seller's documents are tax invoices at 15%, numbered without gaps, and keep the old VAT number (D192, D195, AT35)" do
    @seller.update!(vat_number: "4123456789", legal_name: "Fern & Frond (Pty) Ltd")
    first = order(1)
    second = order(1)
    pay(first, 20000)
    assert_raises(Order::Reserving::Refused) { pay(second, 0) }
    pay(second, 20000)
    invoice = first.reload.receipt
    assert_equal [ "INV-0001", BigDecimal("15"), 2609 ], [ invoice.reference, invoice.vat_rate, invoice.vat_cents ]
    assert invoice.tax_invoice?
    assert_equal "INV-0002", second.reload.receipt.reference

    @seller.update!(vat_number: "4999999999")
    assert_equal "4123456789", invoice.reload.details.dig("seller", "vat_number")

    assert_raises(Order::Reserving::Refused) { first.record_refund!(amount_cents: 20001, method: "eft", paid_on: Date.current, reason: "Too much", member: @member) }
    first.record_refund!(amount_cents: 5000, method: "eft", paid_on: Date.current, reason: "Leaf damaged", member: @member)
    note = first.reload.documents.credit_note.sole
    assert_equal [ "CN-0003", 5000, 652, "Leaf damaged" ], [ note.reference, note.total_cents, note.vat_cents, note.reason ]
    assert_equal [ 15000, "paid" ], [ first.paid_cents, first.payment_state ]
  end

  test "a non-VAT seller's refund issues no credit note" do
    order = order(1)
    pay(order, 20000)
    order.record_refund!(amount_cents: 5000, method: "cash", paid_on: Date.current, reason: "Discount", member: @member)
    assert_equal [ "receipt" ], order.reload.documents.map(&:kind)
  end

  test "a paid order's hold never expires and shows for review (D190)" do
    order = order(2)
    order.reserve!(expires_at: 1.hour.from_now, member: @member)
    pay(order, 10000)
    travel 2.hours do
      ExpireStockHoldsJob.perform_now
      assert order.lines.first.reload.held?
      assert_equal 3, @pothos.reload.totals.available
      assert order.reload.needs_review?
      assert_equal [ order ], @seller.orders.needing_review.to_a
    end
  end

  test "a part-paid order can't be cancelled until refunded; a receipt locks its plants (D197)" do
    order = order(2)
    pay(order, 10000)
    assert_raises(Order::Reserving::Refused) { order.cancel!(reason: "No reply", member: @member) }

    order.change_quantity!(order.lines.first, quantity: 1, member: @member)
    assert AuditEvent.exists?(action: "order.total_changed", target_id: order.id)
    pay(order, 10000)
    assert order.reload.receipted?
    assert_raises(Order::Reserving::Refused) { order.change_quantity!(order.lines.first, quantity: 2, member: @member) }

    order.record_refund!(amount_cents: 20000, method: "eft", paid_on: Date.current, reason: "Changed mind", member: @member)
    order.cancel!(reason: "Changed mind", member: @member)
    assert order.reload.cancelled?
  end

  test "returns go back saleable, stay unavailable when damaged, or are lost (SE06, D196)" do
    order = order(3)
    order.reserve!(expires_at: 1.day.from_now, member: @member)
    order.fulfil!(member: @member, unpaid_confirmed: true)
    line = order.lines.first
    assert_equal 2, @pothos.reload.totals.on_hand

    order.record_return!(line, quantity: 1, location: @greenhouse, outcome: "saleable", reason: "Wrong size", member: @member)
    order.record_return!(line, quantity: 1, location: @greenhouse, outcome: "unavailable", reason: "Arrived damaged", member: @member)
    order.record_return!(line, quantity: 1, location: @greenhouse, outcome: "lost", reason: "Rotted", member: @member)
    totals = @pothos.reload.totals
    assert_equal [ 3, 1, 4 ], [ totals.available, totals.unavailable, totals.on_hand ]
    assert_raises(Order::Reserving::Refused) { order.record_return!(line, quantity: 1, location: @greenhouse, outcome: "saleable", reason: "Again", member: @member) }
    assert_equal 0, order.payments.count
  end

  test "the PDF renders from the frozen copy" do
    @seller.update!(vat_number: "4123456789")
    order = order(1)
    pay(order, 20000)
    pdf = OrderDocument::Pdf.new(order.reload.receipt).render
    assert pdf.start_with?("%PDF")
  end

  private
    def order(quantity)
      @seller.orders.create!(buyer: @buyer).tap { it.add_line!(item: @pothos, quantity: quantity, member: @member) }
    end

    def pay(order, cents) = order.record_payment!(amount_cents: cents, method: "eft", paid_on: Date.current, member: @member)
end
