namespace :capabilities do
  desc "Add every registered capability to Flipper and list Flipper features missing from the registry"
  task sync: :environment do
    unknown = Capabilities.sync!
    puts "Synced #{Capabilities.registry.count} capabilities."
    puts "Not in config/features.yml (review and remove in /madmin/flags): #{unknown.join(', ')}" if unknown.any?
  end
end
