module Gesso::Components
  module NotificationItemHelper
    # notification type → leading icon (svg under icons/) and its colour.
    ICONS = {
      "success" => { icon: "check-circle-2", class: "text-success" },
      "warning" => { icon: "alert-triangle", class: "text-warning" }
    }.freeze

    # Fallback icon for "info" and any unrecognised type.
    DEFAULT_ICON = { icon: "info", class: "text-info" }.freeze

    # Renders a single notification item. This is the public entry point:
    # it maps the notification type to an icon and colour, and the read
    # state to the container and title classes, so the partial stays pure
    # markup.
    #
    # notification is a hash:
    #   title   - the headline
    #   message - supporting text (clamped to two lines)
    #   type    - "success" | "warning" | "info" (default for others)
    #   read    - whether it has been read (mutes it)
    #   time    - relative time label, e.g. "5m ago"
    #
    #   render_notification_item(notification: { title:, message:, … })
    def render_notification_item(notification:)
      icon = ICONS.fetch(notification[:type], DEFAULT_ICON)
      read = notification[:read]

      render("gesso/components/notification_item",
        notification:,
        icon: icon[:icon],
        icon_class: icon[:class],
        container_class: read ? "bg-muted/30 border-transparent" :
                                "bg-primary/5 border-primary/20",
        title_class: read ? "text-muted-foreground" : nil)
    end
  end
end
