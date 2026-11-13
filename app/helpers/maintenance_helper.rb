module MaintenanceHelper
  # Environment maintenance kinds (D121).
  MAINTENANCE_LABELS = {
    "water_change" => "Water change", "top_up" => "Top-up", "filter_clean" => "Filter clean", "dosing" => "Dosing",
    "substrate_vacuum" => "Substrate vacuum", "glass_clean" => "Glass clean", "misting_check" => "Misting check",
    "ventilation_check" => "Ventilation check", "equipment_check" => "Equipment check", "light_check" => "Light check",
    "custom" => "Other"
  }.freeze

  def maintenance_label(kind) = MAINTENANCE_LABELS.fetch(kind)
  def maintenance_title(event) = (event.custom? && event.label) || maintenance_label(event.kind)
  def maintenance_kind_options = MAINTENANCE_LABELS.map { |value, label| [ (value == "custom" ? "Your own" : label), value ] }

  # "30%", "Seachem Flourish · 5 mL"
  def maintenance_details(event)
    amount = event.amount && "#{plain_number(event.amount)}#{event.amount_unit == '%' ? '' : ' '}#{event.amount_unit}"
    [ event.product, amount ].compact_blank.join(" · ").presence
  end

  # A plant or an environment, as a reminder or task names it.
  def subject_name(subject) = subject.is_a?(Plant) ? subject.display_name : subject.name
end
