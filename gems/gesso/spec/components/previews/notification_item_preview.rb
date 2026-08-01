# Previews for the notification item component.
#
# Each scenario renders through render_notification_item
# (Gesso::Components::NotificationItemHelper) via the shared
# notification_item_preview/preview template.
#
# @label Notification Item
class NotificationItemPreview < Lookbook::Preview
  # Usage rules: [Notification item design guidance](/lookbook/pages/components/notification_item)
  #
  # @param type select [info, success, warning]
  # @param title text
  # @param message text
  # @param time text
  # @param read toggle
  def playground(type: "info", title: "New version available",
                 message: "A new version of the app is available.",
                 time: "5m ago", read: false)
    preview(type:, title:, message:, time:, read:)
  end

  def info
    preview(type: "info", title: "New version available",
      message: "A new version of the app is available.",
      time: "5m ago", read: false)
  end

  def success
    preview(type: "success", title: "Report generated",
      message: "Your monthly report is ready for download.",
      time: "30m ago", read: false)
  end

  def warning
    preview(type: "warning", title: "Action required",
      message: "Please review the pending requests in your queue.",
      time: "2h ago", read: false)
  end

  # Read notifications are muted.
  def read
    preview(type: "info", title: "Welcome",
      message: "Thanks for using the app.", time: "1d ago", read: true)
  end

  # Every type rendered together — embedded in the design docs.
  def variants
    render_with_template(template: "notification_item_preview/variants")
  end

  private
    def preview(**notification)
      render_with_template(template: "notification_item_preview/preview",
        locals: { notification: })
    end
end
