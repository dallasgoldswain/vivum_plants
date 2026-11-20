# Orders (D179–D188).
module OrdersHelper
  def order_state_badge(order)
    label = order.fulfilled? ? (order.pickup? ? "Collected" : "Shipped") : order.state.capitalize
    tag.span(label, class: order.reserved? ? "badge-secondary" : "badge-outline")
  end

  def payment_badge(order) = tag.span(order.payment_state.capitalize, class: "badge-outline")

  # Items on the business's stock with what's available, for the add-a-line list.
  def order_item_options(items)
    items.map do |item|
      price = item.listings.find(&:live?)&.price_cents || item.price_cents
      [ [ item.code, item.label, rands(price), "#{item.totals.available} available" ].compact.join(" · "), item.id ]
    end
  end

  def datetime_local_value(time) = time&.strftime("%Y-%m-%dT%H:%M")
end
