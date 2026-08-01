# Previews for the theme toggle component.
#
# Renders through render_theme_toggle (Gesso::Components::ThemeToggleHelper) via
# the shared theme_toggle_preview/preview template.
#
# @label Theme Toggle
class ThemeTogglePreview < Lookbook::Preview
  # Usage rules: [Theme toggle design guidance](/lookbook/pages/components/theme_toggle)
  def default
    render_with_template(template: "theme_toggle_preview/preview")
  end
end
