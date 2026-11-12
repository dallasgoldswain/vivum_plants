# Finding a plant in a collection (UX01): names, nickname, record number and tags, plus
# filters for context, status, TC origin, tag and current environment. Collections are
# personal and small, so a scan with ILIKE is enough; no search index yet.
module Plant::Searchable
  extend ActiveSupport::Concern

  SEARCHED_COLUMNS = %w[ display_name botanical_name cultivar common_name nickname ].freeze

  class_methods do
    def search(query)
      words = query.to_s.squish.split(" ").first(6)
      words.reduce(all) { |relation, word| relation.where(word_condition(word)) }
    end

    def filtered(context: nil, status: nil, tc_origin: nil, tag: nil, environment: nil, unwatered_days: nil)
      relation = all
      current = EnvironmentAssignment.current.select(:plant_id)
      relation =
        case environment.to_s
        when "" then relation
        when "none" then relation.where.not(id: current)
        else relation.where(id: current.where(environment_id: environment.to_i))
        end
      relation = relation.where(growing_context: context) if growing_contexts.key?(context.to_s)
      relation =
        case status.to_s
        when "", "active" then relation.in_active_collection
        when "inactive" then relation.inactive
        when "all" then relation
        else statuses.key?(status.to_s) ? relation.where(status: status) : relation.in_active_collection
        end
      relation = relation.where(tc_origin: true) if tc_origin.to_s == "1"
      relation = relation.where("? = ANY (tags)", tag.to_s.downcase) if tag.present?
      if (days = unwatered_days.to_i).positive?
        # "Not watered in N+ days" (D109), counting plants never watered.
        relation = relation.where.not(id: CareEvent.watering.where(occurred_at: days.days.ago..).select(:plant_id))
      end
      relation
    end

    private
      def word_condition(word)
        pattern = "%#{sanitize_sql_like(word)}%"
        conditions = SEARCHED_COLUMNS.map { "#{table_name}.#{it} ILIKE :pattern" }
        conditions << "array_to_string(#{table_name}.tags, ' ') ILIKE :pattern"
        number = word[/\A(?:p-?)?0*(\d{1,9})\z/i, 1]
        conditions << "#{table_name}.number = :number" if number
        sanitize_sql_array([ "(#{conditions.join(' OR ')})", { pattern: pattern, number: number.to_i } ])
      end
  end
end
