# Seller stock (D155–D163).
module StockHelper
  MOVEMENT_LABELS = {
    "receipt" => "Received", "move" => "Moved", "mark_unavailable" => "Marked unavailable", "mark_available" => "Available again",
    "loss" => "Lost", "adjustment" => "Count adjusted", "hold" => "Held", "release" => "Hold released", "expire" => "Hold expired",
    "fulfil" => "Fulfilled", "to_collection" => "Back to a collection", "return" => "Returned"
  }.freeze
  UNAVAILABLE_REASONS = %w[ Quarantine Damaged Other ].freeze

  # "R450", "R1 250.50"
  def rands(cents)
    return if cents.nil?

    number_to_currency(cents / 100.0, unit: "R", delimiter: " ", precision: (cents % 100).zero? ? 0 : 2, format: "%u%n")
  end

  def stock_kind_label(kind) = kind == "specimen" ? "Specimen" : "Batch"

  # "Moved 3 from Greenhouse to Shop shelf (unavailable)", "Count adjusted −2 at Shelf"
  def movement_summary(movement)
    quantity = movement.adjustment? && movement.quantity.positive? ? "+#{movement.quantity}" : movement.quantity.to_s.sub("-", "−")
    place = movement.move? ? "from #{movement.stock_location.name} to #{movement.to_location.name}" : "at #{movement.stock_location.name}"
    unavailable = movement.bucket_unavailable? && !movement.mark_unavailable? ? " (unavailable)" : ""
    "#{MOVEMENT_LABELS.fetch(movement.kind)} #{quantity} #{place}#{unavailable}"
  end

  def location_options(locations) = locations.map { [ it.name, it.id ] }

  # A price as typed in an import file: "R1 200" when it's an amount, as written when not.
  def import_price(value)
    cents = Order.cents(value)
    cents.negative? ? value : rands(cents)
  end

  # Stock imports (D204–D207): a preview past its 24 hours reads expired before the job runs.
  def import_state_badge(import)
    state = import.previewed? && !import.open? ? "expired" : import.state
    label = { "previewed" => "Preview", "imported" => "Imported", "reversed" => "Reversed", "expired" => "Expired" }.fetch(state)
    tag.span(label, class: state == "imported" ? "badge-secondary" : "badge-outline")
  end
end
