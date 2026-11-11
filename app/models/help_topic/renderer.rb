# Markdown to HTML for help topics and What's new (D74, D79). Raw HTML in the source is
# escaped; headings get ids for help links (help_link "privacy", anchor: "your-choices").
#
# An image names a screenshot pair saved by bin/rails help:screenshots:
#   ![Sell overview on a phone](sell-home)
# renders app/assets/images/help/sell-home-phone.png, with the -desktop.png on wide screens.
class HelpTopic::Renderer < Redcarpet::Render::HTML
  def self.render(markdown)
    Redcarpet::Markdown.new(new, tables: true, no_intra_emphasis: true, fenced_code_blocks: true, lax_spacing: true)
      .render(markdown).html_safe
  end

  def initialize
    super(escape_html: true, safe_links_only: true, with_toc_data: true)
  end

  def image(link, _title, alt)
    helpers = ActionController::Base.helpers
    name = File.basename(link.to_s)
    helpers.tag.picture(class: "vv-help-shot") do
      helpers.tag.source(media: "(min-width: 768px)", srcset: helpers.asset_path("help/#{name}-desktop.png")) +
        helpers.image_tag("help/#{name}-phone.png", alt: alt, loading: "lazy")
    end
  end
end
