# What a document shows, copied when it's issued (D191, D193) so later changes to the seller,
# buyer or order never alter it.
module OrderDocument::Snapshot
  module_function

  def receipt(order)
    {
      "seller" => seller(order.seller),
      "buyer" => { "name" => order.buyer_name, "address" => order.shipping_lines.presence },
      "order" => order.reference,
      "delivery_method" => order.delivery_method,
      "lines" => order.active_lines.map { { "code" => it.stock_item.code, "description" => it.description, "quantity" => it.quantity, "unit_price_cents" => it.unit_price_cents, "total_cents" => it.total_cents } },
      "lines_cents" => order.lines_cents,
      "shipping_cents" => order.shipping_cents,
      "discount_cents" => order.discount_cents,
      "discount_reason" => order.discount_reason,
      "payments" => order.payments.counted.payment.order(:paid_on, :id).map { { "method" => OrderPayment::METHODS[it.method], "paid_on" => it.paid_on.iso8601, "amount_cents" => it.amount_cents, "reference" => it.reference } }
    }
  end

  def credit_note(order, receipt, refund)
    {
      "seller" => seller(order.seller),
      "buyer" => receipt.details["buyer"],
      "order" => order.reference,
      "against" => receipt.reference,
      "refund" => { "method" => OrderPayment::METHODS[refund.method], "paid_on" => refund.paid_on.iso8601, "reference" => refund.reference }
    }
  end

  def seller(seller)
    { "name" => seller.name, "legal_name" => seller.legal_name, "vat_number" => seller.vat_number, "address" => seller.address, "phone" => seller.phone, "email" => seller.contact_email }
  end
end
