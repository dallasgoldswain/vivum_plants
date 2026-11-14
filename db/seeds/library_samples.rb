# Sample platform profiles for development (D142). The launch profiles are written and
# published by operators in Madmin, never seeded in production.
samples = {
  "monstera_deliciosa" => {
    botanical_name: "Monstera deliciosa", synonyms: [ "Philodendron pertusum" ], common_names: [ "Swiss cheese plant" ], family: "Araceae",
    content: {
      "indoor" => {
        "notes" => { "light" => "Bright, indirect light; an hour or two of soft morning sun is fine.", "watering" => "Water when the top third of the mix is dry.", "humidity" => "Average room humidity is fine; aim for 50% or more for larger leaves.", "substrate" => "Chunky aroid mix with bark, perlite and some coir." },
        "reminders" => [ { "kind" => "watering", "label" => nil, "interval" => 7, "interval_unit" => "day" }, { "kind" => "feeding", "label" => nil, "interval" => 1, "interval_unit" => "month" } ]
      }
    },
    references: [ { "title" => "Sample reference for development" } ]
  },
  "anubias_barteri" => {
    botanical_name: "Anubias barteri", common_names: [ "Anubias" ], family: "Araceae",
    content: {
      "aquatic" => {
        "notes" => { "light" => "Low to medium light; shade it from strong light to slow algae on the leaves.", "substrate" => "Tie to rock or wood; don't bury the rhizome.", "feeding" => "Root tabs or liquid fertiliser at water changes." },
        "reminders" => [ { "kind" => "inspection", "label" => nil, "interval" => 2, "interval_unit" => "week" } ]
      }
    },
    references: [ { "title" => "Sample reference for development" } ]
  },
  "phalaenopsis" => {
    botanical_name: "Phalaenopsis", common_names: [ "Moth orchid" ], family: "Orchidaceae",
    content: {
      "indoor" => {
        "notes" => { "light" => "Bright, indirect light; no midday sun.", "watering" => "Soak when the roots turn silvery, then let it drain." },
        "reminders" => [ { "kind" => "watering", "label" => nil, "interval" => 10, "interval_unit" => "day" }, { "kind" => "custom", "label" => "Flush with clean water", "interval" => 1, "interval_unit" => "month" } ]
      }
    },
    references: [ { "title" => "Sample reference for development" } ]
  }
}

samples.each do |key, attributes|
  next if LibraryProfile.exists?(key: key)

  profile = LibraryProfile.new(key: key, botanical_name: attributes[:botanical_name])
  version = profile.versions.new(attributes.merge(status: "in_review", reviewed_on: Date.current))
  profile.save!
  version.publish!(by: nil)
end
