module SubstratesHelper
  CATEGORY_LABELS = {
    "bark" => "Bark", "mineral" => "Mineral", "aggregate" => "Aggregate", "fibre" => "Fibre", "moss" => "Moss",
    "organic" => "Organic", "charcoal" => "Charcoal", "amendment" => "Amendment", "aquatic" => "Aquatic substrate", "other" => "Other"
  }.freeze

  LEVEL_LABELS = { "low" => "Low", "medium" => "Medium", "high" => "High" }.freeze

  def ingredient_category_label(category) = CATEGORY_LABELS.fetch(category.to_s, category.to_s.humanize)
  def ingredient_category_options = CATEGORY_LABELS.map { |value, label| [ label, value ] }
  def ingredient_level_options = LEVEL_LABELS.map { |value, label| [ label, value ] }

  # "3–8 mm", "up to 6 mm", "from 2 mm"
  def particle_size(ingredient)
    low, high = [ ingredient.particle_min_mm, ingredient.particle_max_mm ].map { it && plain_number(it) }
    if low && high then "#{low}–#{high} mm"
    elsif high then "up to #{high} mm"
    elsif low then "from #{low} mm"
    end
  end

  # 2, 1.5, 12.25
  def plain_number(value) = value.to_d.to_s("F").delete_suffix(".0")

  # A component's share as a percentage, to one decimal place: "50%", "33.3%"
  def component_percent(version, component)
    "#{plain_number((version.fraction_for(component) * 100).round(1))}%"
  end

  # How the recipe lists a component: "2 parts", "1 part", "40%"
  def component_quantity(version, component)
    version.percent? ? "#{plain_number(component.quantity)}%" : pluralize(plain_number(component.quantity), "part")
  end

  # 2000 → "2 L", 750 → "750 mL", 1250 → "1.25 L"
  def volume_label(millilitres)
    millilitres >= 1000 ? "#{plain_number((millilitres / 1000.0).round(2))} L" : "#{plain_number(millilitres)} mL"
  end

  # "Aroid mix v2"
  def recipe_version_label(version) = "#{version.recipe.name} #{version.label}"

  # "2 bark : 1 perlite : 1 coir", or "50% bark, 50% pumice"
  def recipe_formula(version)
    if version.percent?
      version.components.map { "#{plain_number(it.quantity)}% #{it.ingredient.name.downcase}" }.join(", ")
    else
      version.components.map { "#{plain_number(it.quantity)} #{it.ingredient.name.downcase}" }.join(" : ")
    end
  end

  # Ready versions a setup can use (D100): the latest ready version of each active recipe,
  # plus the version the plant is on now so keeping it is possible.
  def recipe_version_options(recipes, current_version)
    versions = recipes.filter_map(&:latest_ready_version)
    versions.unshift(current_version) if current_version && versions.exclude?(current_version)
    versions.map { [ recipe_version_label(it), it.id ] }
  end
end
