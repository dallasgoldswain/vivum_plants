# Money on an order (PY03 manual, D189–D197): payments and refunds recorded by hand, voided
# never edited. The payment state follows what's been paid against the total. Being fully
# paid issues the receipt once; any payment pins the order's holds so they never expire on
# their own (D190).
module Order::Payments
  extend ActiveSupport::Concern

  PAYMENT_STATES = { "unpaid" => "Unpaid", "part_paid" => "Part paid", "paid" => "Paid", "overpaid" => "Overpaid" }.freeze

  included do
    has_many :payments, -> { order(:paid_on, :id) }, class_name: "OrderPayment", dependent: :restrict_with_error
    has_many :documents, -> { order(:number) }, class_name: "OrderDocument", dependent: :restrict_with_error
    has_one :receipt, -> { where(kind: "receipt") }, class_name: "OrderDocument"

    validates :payment_state, inclusion: { in: PAYMENT_STATES.keys }
  end

  def paid_cents = payments.select { !it.voided? }.sum(&:signed_cents)
  def refunded_cents = payments.select { it.refund? && !it.voided? }.sum(&:amount_cents)
  # After a receipt a refund is a correction, so it lowers what's due as well (D197).
  def due_cents = receipted? ? total_cents - refunded_cents : total_cents
  def balance_cents = due_cents - paid_cents
  def any_payment? = paid_cents.positive?
  def receipted? = receipt.present?

  # A paid order whose hold time has passed waits for the seller (D190).
  def needs_review? = (reserved? && any_payment? && hold_expires_at&.past?) || payment_state == "overpaid"

  def record_payment!(amount_cents:, method:, paid_on:, member:, reference: nil)
    paying(member) do
      raise Order::Reserving::Refused, "A cancelled order can't take payments." if cancelled?

      payments.create!(kind: "payment", amount_cents: amount_cents, method: method, paid_on: paid_on, reference: reference, recorded_by: member)
    end
  end

  # Never more than has been paid (D194); a VAT seller's refund after a tax invoice also
  # issues a credit note (D195).
  def record_refund!(amount_cents:, method:, paid_on:, reason:, member:, reference: nil)
    paying(member) do
      raise Order::Reserving::Refused, "That's more than has been paid (#{paid_cents / 100.0})." if amount_cents.to_i > paid_cents

      refund = payments.create!(kind: "refund", amount_cents: amount_cents, method: method, paid_on: paid_on, reference: reference, reason: reason, recorded_by: member)
      OrderDocument.issue_credit_note!(refund, member: member)
      refund
    end
  end

  def void_payment!(payment, reason:, member:)
    paying(member) do
      payment.lock!
      next payment if payment.voided?
      raise Order::Reserving::Refused, "Give a reason for voiding it." if reason.to_s.strip.empty?
      raise Order::Reserving::Refused, "This refund has credit note #{payment.credit_note.reference}; record a payment instead." if payment.credit_note
      raise Order::Reserving::Refused, "Voiding it would leave more refunded than paid." if payment.payment? && paid_cents - payment.amount_cents < 0

      payment.update!(voided_at: Time.current, voided_by: member, void_reason: reason)
      payment
    end
  end

  private
    def paying(member)
      transaction do
        lock!
        payments.reset
        result = yield
        payments.reset
        refresh_payment_state!(member)
        Audit.record("order.payment_changed", actor: member, target: self, details: { payment_id: result.id, kind: result.kind, amount_cents: result.amount_cents, voided: result.voided?, payment_state: payment_state })
        result
      end
    rescue ActiveRecord::RecordInvalid => error
      raise Order::Reserving::Refused, error.record.errors.full_messages.to_sentence
    end

    def refresh_payment_state!(member)
      paid = paid_cents
      due = due_cents
      state = if paid <= 0 && due.positive? then "unpaid"
      elsif paid < due then "part_paid"
      elsif paid == due then "paid"
      else "overpaid"
      end
      update!(payment_state: state)
      pin_holds!
      return unless %w[ paid overpaid ].include?(state) && active_lines.any? && !receipted?

      OrderDocument.issue_receipt!(self, member: member)
      association(:receipt).reset
      documents.reset
    end

    def pin_holds!
      StockHold.where(id: lines.select(:stock_hold_id), state: "active").update_all(pinned: any_payment?)
    end
end
