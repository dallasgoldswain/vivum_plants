# One page of the product manual (HM01, D74): app/help/<id>.md, YAML front matter then
# Markdown. Topics ship in the same change as their feature (D30).
#
#   ---
#   id: privacy
#   title: Privacy and your choices
#   summary: One line shown in the list and search results.
#   audience: everyone            # everyone, collector or seller
#   capabilities: [privacy.consents]
#   prerequisites: []             # integration, subscription or rollout notes for the reader
#   keywords: [consent, marketing]
#   reviewed: 2026-11-11          # written by bin/rails "help:review[privacy]" (D77)
#   reviewed_digest: <sha256 of the body>
#   ---
#
# A topic is shown only when all its capabilities are live for the viewer (D75).
class HelpTopic
  DIRECTORY = Rails.root.join("app/help")
  AUDIENCES = %w[ everyone collector seller ].freeze
  FRONT_MATTER = /\A---\n(.*?)\n---\n/m

  class NotFound < StandardError; end
  class Invalid < StandardError; end

  attr_reader :id, :title, :summary, :audience, :capabilities, :prerequisites, :keywords,
    :reviewed, :reviewed_digest, :body, :path

  class << self
    # Cached until code reloads; app/help is watched in development (config/application.rb).
    def all
      @all ||= Dir[directory.join("*.md")].sort.map { |path| load(path) }.sort_by(&:title).freeze
    end

    def reset!
      @all = nil
    end

    # Swap the topic folder (tests); nil restores app/help.
    def directory=(path)
      @directory = path && Pathname(path)
      reset!
    end

    def directory
      @directory || DIRECTORY
    end

    def load(path)
      text = File.read(path)
      front_matter = text[FRONT_MATTER, 1] or raise Invalid, "#{path}: missing front matter"
      new(path: path.to_s, body: text.sub(FRONT_MATTER, ""), **YAML.safe_load(front_matter, permitted_classes: [ Date ]).symbolize_keys)
    end

    def find(id)
      all.find { |topic| topic.id == id.to_s } or raise NotFound, "No help topic #{id}"
    end

    def visible_to(user:, seller:)
      all.select { |topic| topic.visible_to?(user: user, seller: seller) }
    end

    # Every word must appear somewhere; title matches rank above keywords, keywords above text.
    def search(query, user:, seller:)
      words = query.to_s.downcase.scan(/[[:alnum:]]+/)
      return [] if words.empty?

      visible_to(user: user, seller: seller)
        .filter_map { |topic| (score = topic.search_score(words)) && [ topic, score ] }
        .sort_by { |topic, score| [ -score, topic.title ] }
        .map(&:first)
    end

    def covering(key)
      all.select { |topic| topic.capabilities.include?(key.to_s) }
    end

    # Why a capability can't be released to everyone yet (HM02, D76), or nil when it can.
    # Internal, unregistered and unimplemented capabilities have nothing to check.
    def release_blocker(key)
      definition = Capabilities.registry[key]
      return if definition.nil? || !definition.implemented? || definition.internal?

      topics = covering(key)
      return "#{key} has no help topic. Add one in app/help before releasing it to everyone." if topics.empty?

      unreviewed = topics.reject(&:reviewed?).map(&:id)
      if unreviewed.any?
        "Help for #{key} isn't reviewed since its last change (#{unreviewed.join(', ')}). " \
          "Run bin/rails \"help:review[#{unreviewed.first}]\" after reading it."
      end
    end
  end

  def initialize(path:, body:, id:, title:, audience:, summary: nil, capabilities: [], prerequisites: [], keywords: [], reviewed: nil, reviewed_digest: nil)
    @path, @body, @id, @title, @summary, @audience = path, body, id.to_s, title, summary, audience.to_s
    @capabilities, @prerequisites, @keywords = Array(capabilities).map(&:to_s), Array(prerequisites), Array(keywords).map(&:to_s)
    @reviewed, @reviewed_digest = reviewed, reviewed_digest
    validate!
  end

  def to_param = id

  def html
    @html ||= HelpTopic::Renderer.render(body)
  end

  def digest
    Digest::SHA256.hexdigest(body)
  end

  # Reviewed, and the text hasn't changed since (D77).
  def reviewed?
    reviewed.present? && reviewed_digest == digest
  end

  def visible_to?(user:, seller:)
    capabilities.all? { |key| Capabilities.enabled?(key, user: user, seller: seller) }
  end

  def search_score(words)
    title_text, keyword_text, body_text = title.downcase, keywords.join(" ").downcase, plain_text
    words.sum do |word|
      if title_text.include?(word) then 3
      elsif keyword_text.include?(word) then 2
      elsif body_text.include?(word) then 1
      else return nil
      end
    end
  end

  # Records the founder's review in the file's front matter (bin/rails "help:review[id]").
  def review!(on: Date.current)
    text = File.read(path)
    lines = text[FRONT_MATTER, 1].lines.map(&:chomp).reject { |line| line.start_with?("reviewed:", "reviewed_digest:") }
    lines += [ "reviewed: #{on.iso8601}", "reviewed_digest: #{digest}" ]
    File.write(path, text.sub(FRONT_MATTER) { "---\n#{lines.join("\n")}\n---\n" })
    self.class.reset!
  end

  private
    def plain_text
      @plain_text ||= ActionController::Base.helpers.strip_tags(html).downcase
    end

    def validate!
      raise Invalid, "#{path}: id #{id} must match the file name" unless File.basename(path, ".md") == id
      raise Invalid, "#{id}: unknown audience #{audience}" unless AUDIENCES.include?(audience)

      unknown = capabilities.reject { |key| Capabilities.registry.key?(key) }
      raise Invalid, "#{id}: unknown capabilities #{unknown.join(', ')}" if unknown.any?
    end
end
