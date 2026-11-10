# The code-owned list of capabilities (config/features.yml). Validated on load:
# known states, existing dependencies, no cycles, roadmap keys never implemented.
class Capability::Registry
  STATES = %w[ core pilot roadmap ].freeze
  KEY_FORMAT = /\A[a-z][a-z_]*\.[a-z][a-z_]*\z/

  class Invalid < StandardError; end

  include Enumerable

  def self.load(path = Rails.root.join("config/features.yml"))
    new(YAML.safe_load_file(path))
  end

  def initialize(entries)
    @definitions = entries.to_h do |key, attrs|
      key = key.to_s
      attrs = attrs.to_h.transform_keys(&:to_s)
      [ key, Capability::Definition.new(
        key: key,
        domain: attrs.fetch("domain"),
        state: attrs.fetch("state"),
        implemented: attrs.fetch("implemented", false),
        depends_on: Array(attrs["depends_on"]).map(&:to_s),
        entitlement: attrs["entitlement"],
        description: attrs.fetch("description"),
        off: attrs["off"]
      ) ]
    end.freeze
    validate!
  end

  def [](key) = @definitions[key.to_s]
  def key?(key) = @definitions.key?(key.to_s)
  def keys = @definitions.keys
  def each(&) = @definitions.each_value(&)

  private
    def validate!
      each do |definition|
        raise Invalid, "#{definition.key}: key must look like domain.name" unless definition.key.match?(KEY_FORMAT)
        raise Invalid, "#{definition.key}: unknown state #{definition.state}" unless STATES.include?(definition.state)
        raise Invalid, "#{definition.key}: roadmap capabilities cannot be implemented" if definition.roadmap? && definition.implemented?
        missing = definition.depends_on.reject { |dep| key?(dep) }
        raise Invalid, "#{definition.key}: unknown dependencies #{missing.join(', ')}" if missing.any?
      end
      each { |definition| check_cycles(definition.key, []) }
    end

    def check_cycles(key, path)
      raise Invalid, "dependency cycle: #{(path + [ key ]).join(' -> ')}" if path.include?(key)

      self[key].depends_on.each { |dep| check_cycles(dep, path + [ key ]) }
    end
end
