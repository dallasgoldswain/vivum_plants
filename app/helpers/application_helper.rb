module ApplicationHelper
  # Sidebar / bottom-nav link that marks the current page for screen readers and styling.
  def nav_link_to(name, path, **options)
    link_to name, path, **options, aria: { current: (current_page?(path) ? "page" : nil) }
  end

  # The signed-in shell shows only once the user can actually use the app.
  def app_shell?
    user = Current.user
    user.present? && user.email_verified? && !(user.two_factor_required? && !user.two_factor_enabled?)
  end
end
