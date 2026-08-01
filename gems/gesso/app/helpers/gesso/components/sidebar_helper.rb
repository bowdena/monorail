module Gesso::Components
  module SidebarHelper
    # Renders the sidebar component. This is the public entry point: it
    # derives the active section from the current request path and hands
    # the partial nav items already flagged, so the partial stays pure
    # markup.
    #
    #   render_sidebar(app_name: "NHS App", nav_items: [...])
    def render_sidebar(nav_items: [], app_name: "App Name")
      items = nav_items.map do |item|
        item.merge(active: active_item?(item[:path]))
      end

      render("gesso/components/sidebar", nav_items: items, app_name:)
    end

    private
      # The active section is derived from the current request path: an
      # exact match for the root, a prefix match otherwise.
      def active_item?(path)
        (path == "/") ? request.path == "/" : request.path.start_with?(path)
      end
  end
end
