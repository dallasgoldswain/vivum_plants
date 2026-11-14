# Seller stock (D155–D163).
module StockHelper
  MOVEMENT_LABELS = {
    "receipt" => "Received", "move" => "Moved", "mark_unavailable" => "Marked unavailable", "mark_available" => "Available again",
    "loss" => "Lost", "adjustment" => "Count adjusted", "hold" => "Held", "release" => "Hold released", "expire" => "Hold expired",
    "fulfil" => "Fulfilled", "to_collection" => "Back to a collection"
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
end
