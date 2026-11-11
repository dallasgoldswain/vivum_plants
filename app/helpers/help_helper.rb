module HelpHelper
  # A small Help link beside a page heading (D78), shown when contextual help is on and the
  # topic is live for the viewer. An unknown topic id raises, so a typo fails in tests.
  def help_link(topic_id, anchor: nil)
    topic = HelpTopic.find(topic_id)
    return unless capability?("help.contextual") && topic.visible_to?(user: Current.user, seller: Current.seller)

    link_to "Help", help_topic_path(topic, anchor: anchor), class: "vv-help-link", aria: { label: "Help: #{topic.title}" }
  end

  def whats_new_unseen?
    WhatsNew.unseen_by?(Current.user)
  end
end
