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
