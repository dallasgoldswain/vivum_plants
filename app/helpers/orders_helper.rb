# Orders (D179–D188).
module OrdersHelper
  def order_state_badge(order)
    label = order.fulfilled? ? (order.pickup? ? "Collected" : "Shipped") : order.state.capitalize
    tag.span(label, class: order.reserved? ? "badge-secondary" : "badge-outline")
  end

  def payment_badge(order)
    tag.span(Order::Payments::PAYMENT_STATES.fetch(order.payment_state), class: order.fully_paid? ? "badge-secondary" : "badge-outline")
  end

  # Items on the business's stock with what's available, for the add-a-line list.
  def order_item_options(items)
    items.map do |item|
      price = item.listings.find(&:live?)&.price_cents || item.price_cents
      [ [ item.code, item.label, rands(price), "#{item.totals.available} available" ].compact.join(" · "), item.id ]
    end
  end

  # A form value in rands: "85.00".
  def rand_amount(cents) = format("%.2f", cents / 100.0)

  def datetime_local_value(time) = time&.strftime("%Y-%m-%dT%H:%M")
end
