# Previews for the header component.
#
# Each scenario renders through render_header (Gesso::Components::HeaderHelper)
# via the shared header_preview/preview template.
#
# @label Header
class HeaderPreview < Lookbook::Preview
  # Usage rules: [Header design guidance](/lookbook/pages/components/header)
  def default
    preview(
      title: "Dashboard",
      user_name: "Jane Smith",
      user_initials: "JS",
      user_email: "jane.smith@nhs.net",
      notifications: [
        {
          title: "Welcome!",
          message: "Thanks for using the app. Explore the dashboard to get started.",
          type: "info",
          read: false,
          time: "5m ago"
        },
        {
          title: "Report Generated",
          message: "Your monthly report is ready for download.",
          type: "success",
          read: false,
          time: "30m ago"
        },
        {
          title: "Action Required",
          message: "Please review the pending requests in your queue.",
          type: "warning",
          read: true,
          time: "2h ago"
        }
      ]
    )
  end

  def no_notifications
    preview(
      user_name: "Jane Smith",
      user_initials: "JS",
      user_email: "jane.smith@nhs.net",
      notifications: []
    )
  end

  private
    def preview(title: nil, show_search: true, user_name: "User",
                user_initials: "U", user_email: "", notifications: [])
      render_with_template(template: "header_preview/preview",
        locals: { title:, show_search:, user_name:, user_initials:,
                  user_email:, notifications: })
    end
end
