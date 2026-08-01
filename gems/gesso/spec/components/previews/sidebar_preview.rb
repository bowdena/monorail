# Previews for the sidebar component.
#
# Renders through render_sidebar (Gesso::Components::SidebarHelper) via the
# shared sidebar_preview/preview template.
#
# @label Sidebar
class SidebarPreview < Lookbook::Preview
  # Usage rules: [Sidebar design guidance](/lookbook/pages/components/sidebar)
  def default
    preview(
      app_name: "NHS App",
      nav_items: [
        { label: "Dashboard", path: "/", icon: "layout-dashboard" },
        { label: "Patients", path: "/patients", icon: "users" },
        { label: "Changelog", path: "/changelog", icon: "history" },
        { label: "Settings", path: "/settings", icon: "settings" },
        { label: "Support", path: "/support", icon: "life-buoy" }
      ]
    )
  end

  private
    def preview(nav_items: [], app_name: "App Name")
      render_with_template(template: "sidebar_preview/preview",
        locals: { nav_items:, app_name: })
    end
end
