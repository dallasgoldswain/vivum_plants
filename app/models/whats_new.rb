# The user-facing release notes in WHATS_NEW.md, shown at /whats-new (D79).
module WhatsNew
  PATH = Rails.root.join("WHATS_NEW.md")
  DATED_HEADING = /^## (\d{4}-\d{2}-\d{2})/

  class << self
    # Swap the file (tests); nil restores WHATS_NEW.md.
    attr_writer :path

    def path
      @path || PATH
    end

    # The writing rules at the top of the file are an HTML comment for editors, not readers.
    def html
      HelpTopic::Renderer.render(source.gsub(/<!--.*?-->/m, "").sub(/\A\s*# What's new\s*/, ""))
    end

    # Date of the newest released entry; nil while everything is "Coming soon".
    def published_on
      source.scan(DATED_HEADING).flatten.map { |date| Date.iso8601(date) }.max
    end

    # A dot on the sidebar link until the user opens the page after the newest entry.
    def unseen_by?(user)
      return false unless user

      seen = user.whats_new_seen_at
      seen.nil? || (published_on.present? && seen.to_date < published_on)
    end

    private
      def source
        File.read(path)
      end
  end
end
