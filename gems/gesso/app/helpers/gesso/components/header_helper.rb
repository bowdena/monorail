module Gesso::Components
  module HeaderHelper
    # Renders the header component — the shell's top bar. This is the
    # public entry point: it computes the unread notification count and
    # badge label, so the partial stays pure markup.
    #
    #   render_header(title: "Dashboard", user_name: "Jane Smith",
    #                 notifications: [...])
    def render_header(title: nil, show_search: true, user_name: "User",
                      user_initials: "U", user_email: "", notifications: [])
      unread_count = notifications.count { |n| !n[:read] }
      unread_label = (unread_count > 9) ? "9+" : unread_count.to_s

      render("gesso/components/header",
        title:, show_search:, user_name:, user_initials:, user_email:,
        notifications:, unread_count:, unread_label:)
    end
  end
end
