module EnvironmentsHelper
  KIND_LABELS = {
    "room_shelf" => "Room or shelf", "grow_cabinet" => "Grow cabinet", "terrarium" => "Terrarium",
    "paludarium" => "Paludarium", "aquarium" => "Aquarium", "acclimatisation" => "Acclimatisation container",
    "outdoor_bed" => "Outdoor bed"
  }.freeze

  WATERING_LABELS = {
    "top" => "Top watering", "bottom" => "Bottom watering", "self_watering" => "Self-watering pot",
    "wick" => "Wick", "semi_hydro" => "Semi-hydro", "submerged" => "Submerged", "misting" => "Misting"
  }.freeze

  def environment_kind_label(kind) = KIND_LABELS.fetch(kind.to_s, kind.to_s.humanize)
  def environment_kind_options = KIND_LABELS.map { |value, label| [ label, value ] }
  def watering_method_options = WATERING_LABELS.map { |value, label| [ label, value ] }

  # "Terracotta pot · 12 cm · Bottom watering · Aroid mix v2"
  def setup_summary(setup)
    return unless setup

    size = setup.size && "#{setup.size.to_s('F').delete_suffix('.0')} #{setup.size_unit}"
    recipe = setup.recipe_version && "#{setup.recipe_version.recipe.name} #{setup.recipe_version.label}"
    [ setup.container, size, WATERING_LABELS[setup.watering_method], recipe ].compact.join(" · ")
  end

  # "60 × 30 × 45 cm · 81 L"
  def environment_dimensions(environment)
    sides = [ environment.length_cm, environment.width_cm, environment.height_cm ].compact.map { it.to_s("F").delete_suffix(".0") }
    volume = environment.volume_litres && "#{environment.volume_litres.to_s('F').delete_suffix('.0')} L"
    [ (sides.join(" × ") + " cm" if sides.any?), volume ].compact.join(" · ").presence
  end

  def environment_thumb(environment, **options)
    if (photo = environment.cover_photo) && photo.image.attached?
      image_tag photo.image.variant(:thumb), alt: "", loading: "lazy", **options
    else
      tag.div(environment.name.first.upcase, class: "vv-plant-placeholder #{options[:class]}", aria: { hidden: true })
    end
  end

  # Environments a plant can move into, for a select.
  def environment_options(environments)
    environments.map { [ "#{it.name} (#{environment_kind_label(it.kind).downcase})", it.id ] }
  end
end
