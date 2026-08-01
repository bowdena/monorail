# Previews for the combobox component.
#
# Each scenario renders through render_combobox
# (Gesso::Components::ComboboxHelper) via the shared combobox_preview/preview
# template.
#
# @label Combobox
class ComboboxPreview < Lookbook::Preview
  # Usage rules: [Combobox design guidance](/lookbook/pages/components/combobox)
  def default
    preview(
      name: "framework",
      selected: "rails",
      placeholder: "Select framework…",
      options: [
        { value: "rails",   label: "Ruby on Rails" },
        { value: "django",  label: "Django" },
        { value: "laravel", label: "Laravel" },
        { value: "express", label: "Express.js" },
        { value: "spring",  label: "Spring Boot" }
      ]
    )
  end

  # No selection: shows placeholder text.
  def no_selection
    preview(
      name: "framework",
      placeholder: "Select framework…",
      options: [
        { value: "rails",   label: "Ruby on Rails" },
        { value: "django",  label: "Django" },
        { value: "laravel", label: "Laravel" }
      ]
    )
  end

  private
    def preview(name: nil, options: [], selected: nil,
                placeholder: "Select…", id: nil)
      render_with_template(template: "combobox_preview/preview",
        locals: { name:, options:, selected:, placeholder:, id: })
    end
end
