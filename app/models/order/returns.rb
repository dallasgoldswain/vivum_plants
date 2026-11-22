# Plants a buyer sent back after fulfilment (SE06, D196). The units come back through the
# ledger into the bucket the seller chose; returning never refunds by itself.
module Order::Returns
  extend ActiveSupport::Concern

  def record_return!(line, quantity:, location:, outcome:, reason:, member:)
    quantity = quantity.to_i
    transaction do
      lock!
      line.lock!
      raise Order::Reserving::Refused, "Only fulfilled orders take returns." unless fulfilled?
      raise Order::Reserving::Refused, "That plant wasn't sent." unless line.order_id == id && line.active?
      raise Order::Reserving::Refused, "Only #{line.returnable_quantity} can come back." unless quantity.between?(1, line.returnable_quantity)

      returned = line.returns.create!(quantity: quantity, stock_location: location, outcome: outcome, reason: reason, member: member)
      Stock::Ledger.new(line.stock_item, member: member).return!(quantity: quantity, location: location, outcome: outcome, reason: "#{reference}: #{returned.reason}")
      Audit.record("order.returned", actor: member, target: self, details: { line_id: line.id, quantity: quantity, outcome: outcome })
      returned
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Order::Reserving::Refused, error.record.errors.full_messages.to_sentence
  rescue Stock::Ledger::Refused => error
    raise Order::Reserving::Refused, error.message
  end
end
