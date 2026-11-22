# A receipt, tax invoice or credit note (RC01, D08, D191–D195): a frozen copy of what it
# shows, numbered from one gap-free sequence per seller. The number comes from the seller's
# counter in the same transaction, so a failed issue leaves no gap. Never changed once issued.
class OrderDocument < ApplicationRecord
  KINDS = %w[ receipt credit_note ].freeze
  VAT_RATE = BigDecimal("15")

  belongs_to :seller
  belongs_to :order
  belongs_to :order_payment, optional: true
  belongs_to :issued_by, class_name: "User", optional: true

  enum :kind, KINDS.index_by(&:itself), validate: true

  scope :by_number, -> { order(:number) }

  # Issued once, when the order becomes fully paid (D191).
  def self.issue_receipt!(order, member:)
    order.documents.receipt.first || issue!(order, kind: "receipt", total_cents: order.total_cents, member: member, details: Snapshot.receipt(order))
  end

  # For a VAT seller, a refund on an order with a tax invoice (D195).
  def self.issue_credit_note!(refund, member:)
    order = refund.order
    receipt = order.receipt
    return unless receipt&.tax_invoice?

    issue!(order, kind: "credit_note", total_cents: refund.amount_cents, member: member, payment: refund, reason: refund.reason,
      vat: true, details: Snapshot.credit_note(order, receipt, refund))
  end

  def self.issue!(order, kind:, total_cents:, member:, details:, payment: nil, reason: nil, vat: order.seller.vat_number.present?)
    seller = order.seller
    number = seller.class.connection.select_value(
      seller.class.sanitize_sql_array([ "UPDATE sellers SET last_document_number = last_document_number + 1 WHERE id = ? RETURNING last_document_number", seller.id ])
    ).to_i
    prefix = kind == "credit_note" ? "CN" : (vat ? "INV" : "R")
    create!(seller: seller, order: order, order_payment: payment, kind: kind, number: number, reference: format("%s-%04d", prefix, number),
      total_cents: total_cents, vat_rate: (VAT_RATE if vat), vat_cents: (vat_in(total_cents) if vat), reason: reason,
      details: details, issued_by: member, issued_at: Time.current)
  end

  # VAT included in a VAT-inclusive amount: amount × rate ÷ (100 + rate).
  def self.vat_in(cents) = (cents * VAT_RATE / (100 + VAT_RATE)).round.to_i

  def tax_invoice? = receipt? && vat_rate.present?
  def title = credit_note? ? "Credit note" : (tax_invoice? ? "Tax invoice" : "Receipt")
  def readonly? = persisted?
end
