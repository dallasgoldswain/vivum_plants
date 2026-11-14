# The care content a profile or a platform version holds (GU01, D143): names, per-context
# notes and suggested reminders, and references. Shared by LibraryProfile and
# LibraryProfileVersion, which keep the same columns.
module LibraryProfile::Contents
  extend ActiveSupport::Concern

  NOTE_FIELDS = %w[ light watering humidity temperature substrate feeding ].freeze
  REMINDER_ROWS = 4
  REFERENCE_ROWS = 4
  Suggestion = Data.define(:kind, :label, :interval, :interval_unit) do
    def matches?(schedule) = schedule.matches?(kind, label)
    def same_cadence?(schedule) = schedule.interval == interval && schedule.interval_unit == interval_unit
  end
  Reference = Data.define(:title, :url)

  included do
    normalizes :botanical_name, :family, with: ->(value) { value.squish.presence }

    validates :botanical_name, presence: true, length: { maximum: 120 }
    validates :family, length: { maximum: 80 }
    validate :content_is_valid
  end

  # Comma-separated fields on the forms.
  def synonym_list = synonyms.join(", ")
  def synonym_list=(value)
    self.synonyms = split_list(value)
  end

  def common_name_list = common_names.join(", ")
  def common_name_list=(value)
    self.common_names = split_list(value)
  end

  def display_name = botanical_name
  def contexts = Plant::GROWING_CONTEXTS.select { content.key?(it) }
  def notes_for(context) = content.dig(context, "notes").to_h.slice(*NOTE_FIELDS).compact_blank
  def suggestions_for(context) = Array(content.dig(context, "reminders")).map { Suggestion.new(**it.symbolize_keys.slice(*Suggestion.members)) }
  def reference_list = references.map { Reference.new(**it.symbolize_keys.slice(*Reference.members)) }
  def covers?(context) = notes_for(context).any? || suggestions_for(context).any?

  # Form params: content[indoor][notes][light], content[indoor][reminders][0][kind], ….
  # Blank notes and incomplete reminder rows are dropped; contexts with nothing are left out.
  def content_params=(params)
    params = params.to_h.with_indifferent_access
    self.content = Plant::GROWING_CONTEXTS.each_with_object({}) do |context, result|
      given = params[context].to_h.with_indifferent_access
      notes = given[:notes].to_h.slice(*NOTE_FIELDS).transform_values { it.to_s.strip }.compact_blank
      reminders = given[:reminders].to_h.values.filter_map do |row|
        next if row[:kind].blank? || row[:interval].blank?

        { "kind" => row[:kind], "label" => row[:label].to_s.squish.presence, "interval" => row[:interval].to_i, "interval_unit" => row[:interval_unit] }
      end
      result[context] = { "notes" => notes, "reminders" => reminders } if notes.any? || reminders.any?
    end
  end

  def reference_params=(rows)
    self.references = rows.to_h.values.filter_map do |row|
      row = row.to_h.with_indifferent_access
      { "title" => row[:title].to_s.squish, "url" => row[:url].to_s.strip.presence }.compact if row[:title].present?
    end
  end

  def content_fields = %i[ botanical_name synonyms common_names family content references ]

  private
    def split_list(value) = value.to_s.split(",").map(&:squish).compact_blank.uniq

    def content_is_valid
      errors.add(:synonyms, "can't be more than 20") if synonyms.size > 20
      errors.add(:common_names, "can't be more than 20") if common_names.size > 20
      content.each do |context, data|
        next errors.add(:content, "has an unknown growing context") unless Plant::GROWING_CONTEXTS.include?(context)

        data["notes"].to_h.each_value { errors.add(:content, "notes can be up to 500 characters each") if it.to_s.length > 500 }
        Array(data["reminders"]).each do |row|
          schedule = CareSchedule.new(kind: row["kind"], label: row["label"], interval: row["interval"], interval_unit: row["interval_unit"])
          unless CareSchedule::KINDS.include?(row["kind"]) && row["interval"].to_i.between?(1, 365) && CareSchedule::INTERVAL_UNITS.include?(row["interval_unit"]) && (!schedule.custom? || row["label"].present?)
            errors.add(:content, "has a reminder that needs a kind, an interval of 1 to 365, a unit, and a label for your own kind")
          end
        end
      end
      references.each do |reference|
        url = reference["url"]
        errors.add(:references, "need a web address starting with http:// or https://") if url && !url.match?(%r{\Ahttps?://\S+\z})
      end
    end
end
