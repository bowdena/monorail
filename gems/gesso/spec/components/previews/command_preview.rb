# Previews for the command component.
#
# Each scenario renders through render_command (Gesso::Components::CommandHelper)
# via the shared command_preview/preview template.
#
# @label Command
class CommandPreview < Lookbook::Preview
  # Usage rules: [Command design guidance](/lookbook/pages/components/command)
  def default
    preview(
      placeholder: "Search…",
      groups: [
        {
          label: "Navigation",
          items: [
            { label: "Dashboard", href: "/dashboard",
              icon: "layout-dashboard" },
            { label: "Patients",  href: "/patients",  icon: "users" },
            { label: "Settings",  href: "/settings",  icon: "settings" }
          ]
        },
        {
          label: "Actions",
          items: [
            { label: "New patient", href: "/patients/new", icon: "user" },
            { label: "Reports",     href: "/reports", icon: "file-text" }
          ]
        }
      ]
    )
  end

  # Custom empty state text.
  def custom_empty
    preview(empty: "Nothing here yet.", groups: [])
  end

  private
    def preview(groups: [], placeholder: "Search…", empty: nil)
      render_with_template(template: "command_preview/preview",
        locals: { groups:, placeholder:, empty: })
    end
end
