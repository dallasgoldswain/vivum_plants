# Feature flags (PRD §28, D46–D48). Flipper stores on/off state; config/features.yml is the
# registry of allowed keys and app/models/capabilities.rb is the only API code should use.
#
# Defaults kept from the Flipper engine: memoize and preload per request, log checks,
# warn on unknown features in development, and an in-memory adapter in tests.

# Reload the registry when config/features.yml changes in development.
Rails.application.config.watchable_files << Rails.root.join("config/features.yml").to_s

Rails.application.config.to_prepare do
  Flipper::UI.configure do |config|
    # Keys come only from the registry: no creating or deleting features in the console.
    config.feature_creation_enabled = false
    config.feature_removal_enabled = false

    config.fun = false
    config.cloud_recommendation = false
    config.version_check_enabled = false
    config.application_href = "/madmin"
    config.confirm_fully_enable = true
    config.show_feature_description_in_list = true
    config.add_actor_placeholder = "User;12 or Seller;3"
    config.banner_text = "Flags are listed in config/features.yml. Disabling a flag clears every target (emergency stop)."
    config.banner_class = "warning"

    config.descriptions_source = lambda do |keys|
      keys.filter_map { |key| (definition = Capabilities.registry[key]) && [ key, "#{definition.description} · #{definition.state}#{' · not implemented' unless definition.implemented?}" ] }.to_h
    end

    config.actor_names_source = lambda do |flipper_ids|
      ids = flipper_ids.group_by { |id| id.split(";").first }.transform_values { |list| list.map { |id| id.split(";").last } }
      names = {}
      User.where(id: ids["User"]).each { |user| names[user.flipper_id] = user.email_address } if ids["User"]
      Seller.where(id: ids["Seller"]).each { |seller| names[seller.flipper_id] = seller.name } if ids["Seller"]
      names
    end
  end
end

# Audit every flag change (FF04, D49): enable, disable, targets added or removed, and
# features added by capabilities:sync. Checks (enabled?) are not recorded.
FLAG_WRITE_OPERATIONS = %i[ enable disable add remove clear ].freeze

ActiveSupport::Notifications.subscribe("feature_operation.flipper") do |*, payload|
  next unless FLAG_WRITE_OPERATIONS.include?(payload[:operation])

  thing = payload[:thing]
  Audit.record(
    "flag.#{payload[:operation]}",
    target_key: payload[:feature_name].to_s,
    details: { gate: payload[:gate_name], value: thing.respond_to?(:value) ? thing.value : thing }.compact
  )
end

# Releasing a capability to everyone needs a reviewed help topic (HM02, D76). Development
# and test skip the check so flags can be flipped freely while building.
# Loaded once at boot (lib/, not autoloaded): Flipper keeps the class it is given.
require_relative "../../lib/flag_release_guard"

if Rails.env.production?
  Flipper.configure do |config|
    config.use FlagReleaseGuard
  end
end
