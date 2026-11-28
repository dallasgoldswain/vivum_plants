# The To ship list (PK01, D240–D243): reserved orders paid in full, oldest payment first.
# Packed is an optional tick with member and time that can be undone until the order ships.
# A paid order's lines are fixed by its receipt, so packing never has to follow line changes.
# Shipping or collection itself is Order::Reserving#fulfil!.
module Order::Packing
  extend ActiveSupport::Concern

  included do
    belongs_to :packed_by, class_name: "User", optional: true

    scope :to_ship, -> {
      first_paid = OrderPayment.where("order_payments.order_id = orders.id").where(kind: "payment", voided_at: nil).select("MIN(order_payments.paid_on)")
      where(state: "reserved", payment_state: %w[ paid overpaid ]).order(Arel.sql("(#{first_paid.to_sql}) ASC NULLS LAST"), :number)
    }
  end

  def packed? = packed_at.present?
  def to_ship? = reserved? && fully_paid?

  def pack!(member:)
    with_lock do
      raise Order::Reserving::Refused, "Only a paid order waiting to ship can be packed." unless to_ship?
      next self if packed?

      update!(packed_at: Time.current, packed_by: member)
      Audit.record("order.packed", actor: member, target: self)
      self
    end
  end

  def unpack!(member:)
    with_lock do
      raise Order::Reserving::Refused, "#{reference} has been #{pickup? ? 'collected' : 'shipped'}; use a return instead." if fulfilled?
      next self unless packed?

      update!(packed_at: nil, packed_by: nil)
      Audit.record("order.unpacked", actor: member, target: self)
      self
    end
  end
end
