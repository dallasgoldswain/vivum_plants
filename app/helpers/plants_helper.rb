module PlantsHelper
  CONTEXT_LABELS = { "indoor" => "Indoor", "terrarium" => "Terrarium", "paludarium" => "Paludarium", "aquatic" => "Aquatic", "outdoor" => "Outdoor" }.freeze

  def growing_context_label(context) = CONTEXT_LABELS.fetch(context.to_s, context.to_s.humanize)
  def plant_status_label(status) = status.to_s.humanize

  def growing_context_options
    CONTEXT_LABELS.map { |value, label| [ label, value ] }
  end

  def plant_status_options
    (Plant::STATUSES - %w[ moved_to_stock ]).map { [ plant_status_label(it), it ] }
  end

  def plant_status_badge(plant)
    tag.span(plant_status_label(plant.status), class: plant.active? ? "badge-secondary" : "badge-outline") unless plant.status == "active"
  end

  # Botanical name, cultivar in quotes, as growers write it.
  def plant_identity(plant)
    [ plant.botanical_name, plant.cultivar.presence && "‘#{plant.cultivar}’" ].compact.join(" ").presence
  end

  def acquisition_cost(acquisition)
    return if acquisition&.cost_cents.nil?

    "#{acquisition.currency} #{number_with_precision(acquisition.cost_cents / 100.0, precision: 2, delimiter: ' ')}"
  end

  def plant_thumb(plant, **options)
    if (photo = plant.cover_photo) && photo.image.attached?
      image_tag photo.image.variant(:thumb), alt: "", loading: "lazy", **options
    else
      tag.div(plant.display_name.first.upcase, class: "vv-plant-placeholder #{options[:class]}", aria: { hidden: true })
    end
  end
end
