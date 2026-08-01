# Previews for the tabs component.
#
# Renders through render_tabs (Gesso::Components::TabsHelper) via the shared
# tabs_preview/preview template.
#
# @label Tabs
class TabsPreview < Lookbook::Preview
  # Usage rules: [Tabs design guidance](/lookbook/pages/components/tabs)
  def default
    preview(id: "demo", tabs: [
      { label: "Profile", content: "Your profile details." },
      { label: "Preferences", content: "Your preferences." }
    ])
  end

  private
    def preview(id: "tabs", tabs: [])
      render_with_template(template: "tabs_preview/preview",
        locals: { id:, tabs: })
    end
end
