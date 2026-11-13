module CareHelper
  # What the care buttons say (D103).
  CARE_BUTTONS = {
    "watering" => "Water", "feeding" => "Feed", "repotting" => "Repot", "pruning" => "Prune",
    "treatment" => "Treat", "inspection" => "Inspect", "custom" => "Other"
  }.freeze

  # How a timeline entry is headed.
  CARE_TITLES = {
    "observation" => "Observation", "watering" => "Watered", "feeding" => "Fed", "repotting" => "Repotted",
    "pruning" => "Pruned", "treatment" => "Treated", "inspection" => "Inspected", "custom" => "Other care",
    "movement" => "Moved", "setup" => "Setup", "stage" => "Stage", "splitting" => "Split"
  }.freeze

  # The timeline's kind filter (D109).
  CARE_FILTERS = {
    "observation" => "Observations", "watering" => "Watering", "feeding" => "Feeding", "repotting" => "Repotting",
    "pruning" => "Pruning", "treatment" => "Treatments", "inspection" => "Inspections", "custom" => "Other care",
    "movement" => "Moves", "setup" => "Setup changes", "stage" => "Stages", "splitting" => "Splits", "maintenance" => "Environment care"
  }.freeze

  WATERING_METHOD_LABELS = { "top" => "From the top", "bottom" => "Bottom watered", "soak" => "Soaked", "mist" => "Misted" }.freeze
  STRENGTH_LABELS = { "full" => "Full strength", "half" => "Half strength", "quarter" => "Quarter strength" }.freeze

  def care_button_label(kind) = CARE_BUTTONS.fetch(kind)
  def care_title(event) = (event.custom? && event.label) || CARE_TITLES.fetch(event.kind)
  def care_watering_method_options = WATERING_METHOD_LABELS.map { |value, label| [ label, value ] }
  def care_strength_options = STRENGTH_LABELS.map { |value, label| [ label, value ] }

  # "500 mL · Bottom watered", "Seaweed feed · 2 mL/L · Half strength", "Neem oil for thrips · 5 mL/L"
  def care_details(event)
    amount = event.amount && "#{plain_number(event.amount)} #{event.amount_unit}"
    case event.kind
    when "watering" then [ amount, WATERING_METHOD_LABELS[event.watering_method] ]
    when "feeding" then [ event.product, amount, STRENGTH_LABELS[event.strength] ]
    when "treatment" then [ [ event.product, ("for #{event.target}" if event.target) ].compact.join(" "), amount ]
    when "repotting" then [ ("Into #{setup_summary(event.plant_setup)}" if event.plant_setup) ]
    when "inspection" then [ tc_check_details(event) ]
    else []
    end.compact_blank.join(" · ").presence
  end

  # "today", "yesterday", "3 days ago", "2 weeks ago", "in March 2026"
  def care_ago(time)
    days = (Date.current - time.to_date).to_i
    if days <= 0 then "today"
    elsif days == 1 then "yesterday"
    elsif days < 14 then "#{days} days ago"
    elsif days < 60 then "#{days / 7} weeks ago"
    else "in #{l(time.to_date, format: '%B %Y')}"
    end
  end

  # "Watered 3 days ago · Fed 2 weeks ago · Repotted in March 2026" (D109)
  def last_care_summary(latest)
    CareEvent::SUMMARY_KINDS.filter_map { |kind| latest[kind] && "#{CARE_TITLES[kind]} #{care_ago(latest[kind])}" }.join(" · ").presence
  end

  # The collection's watering line (D109).
  def last_watered(time) = time ? "Watered #{care_ago(time)}" : "Not watered yet"

  # Units an amount can be given in, with the first as the default.
  def care_amount_units(kind) = CareEvent::AMOUNT_UNITS.fetch(kind)

  # Observations and logged care share one timeline partial; moves, setups, status changes
  # and photos have their own.
  def timeline_partial(entry)
    name = entry.record.is_a?(CareEvent) && !entry.record.kind.in?(CareEvent::PLACEMENT_KINDS) ? "care" : entry.kind
    "plants/timeline/#{name}"
  end

  # --- Reminders (CA02, CA03, D111–D120) ----------------------------------------

  INTERVAL_UNIT_LABELS = { "day" => "days", "week" => "weeks", "month" => "months" }.freeze

  # What a reminder asks you to do: "Water", "Feed", or your own label.
  # Environment reminders use the maintenance names (D125).
  def care_task_title(task_or_schedule)
    return task_or_schedule.label if task_or_schedule.kind == "custom" && task_or_schedule.label
    task_or_schedule.environment_id ? MaintenanceHelper::MAINTENANCE_LABELS.fetch(task_or_schedule.kind) : CARE_BUTTONS.fetch(task_or_schedule.kind)
  end

  # "Every 7 days after it's done", "Every 2 weeks on fixed dates", "Once"
  def schedule_cadence(schedule)
    return "Once" if schedule.once?

    every = schedule.interval == 1 ? "Every #{schedule.interval_unit}" : "Every #{schedule.interval} #{INTERVAL_UNIT_LABELS[schedule.interval_unit]}"
    "#{every} #{schedule.fixed? ? 'on fixed dates' : "after it's done"}"
  end

  # "3 days overdue", "Due today", "Due tomorrow", "Due Thu 19 Nov"
  def task_due_label(task, today = Date.current)
    days = (task.due_on - today).to_i
    if days < -1 then "#{-days} days overdue"
    elsif days == -1 then "1 day overdue"
    elsif days.zero? then "Due today"
    elsif days == 1 then "Due tomorrow"
    else "Due #{l(task.due_on, format: '%a %-d %b')}"
    end
  end

  def interval_unit_options = INTERVAL_UNIT_LABELS.map { |value, label| [ label, value ] }
  def schedule_kind_options(subject)
    return maintenance_kind_options if subject.is_a?(Environment)

    CareSchedule::KINDS.map { [ (it == "custom" ? "Your own" : CARE_BUTTONS[it]), it ] }
  end

  # Timezones by their IANA name (what browsers report), with the current one kept even if
  # it isn't among Rails' friendly names (D117).
  def time_zone_options(current)
    zones = ActiveSupport::TimeZone.all.map { [ it.to_s, it.tzinfo.name ] }.uniq(&:last)
    zones.unshift([ current, current ]) unless zones.any? { it.last == current }
    options_for_select(zones, current)
  end
end
