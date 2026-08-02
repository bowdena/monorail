# Previews for the button component.
#
# Each scenario renders through render_button (Gesso::Components::ButtonHelper)
# via the shared button_preview/preview template.
#
# @label Button
class ButtonPreview < Lookbook::Preview
  # Usage rules: [Button design guidance](/lookbook/pages/components/button)
  #
  # @param variant select [default, primary, secondary, outline, ghost, link, destructive, warning, info]
  # @param size select [default, xs, sm, lg, icon, icon-xs, icon-sm, icon-lg]
  # @param loading toggle
  # @param disabled toggle
  # @param label text
  def playground(variant: "primary", size: "default", loading: false,
                 disabled: false, label: "Button")
    preview(variant:, size:, loading:, disabled:, label:)
  end

  # Every variant rendered together — embedded in the design docs.
  def variants
    render_with_template(template: "button_preview/variants")
  end

  def primary
    preview(variant: "primary", label: "Primary")
  end

  def secondary
    preview(variant: "secondary", label: "Secondary")
  end

  def outline
    preview(variant: "outline", label: "Outline")
  end

  def ghost
    preview(variant: "ghost", label: "Ghost")
  end

  def link
    preview(variant: "link", label: "Link")
  end

  def destructive
    preview(variant: "destructive", label: "Destructive")
  end

  def warning
    preview(variant: "warning", label: "Warning")
  end

  def info
    preview(variant: "info", label: "Info")
  end

  def extra_small
    preview(size: "xs", label: "Extra small")
  end

  def small
    preview(size: "sm", label: "Small")
  end

  def large
    preview(size: "lg", label: "Large")
  end

  def icon
    preview(variant: "ghost", size: "icon", label: "★",
            aria: { label: "Add to favourites" })
  end

  # An icon beside its label — the label names the action, the icon
  # speeds recognition.
  def with_icon
    render_with_template(template: "button_preview/with_icon")
  end

  # A submit button in a real form — the loading state must never cancel
  # the submission that started it.
  def in_a_form
    render_with_template(template: "button_preview/in_a_form")
  end

  # A submit button whose form targets a frame it sits outside of. The
  # response never replaces the button, so the spinner has to stop
  # itself.
  def in_a_frame
    render_with_template(template: "button_preview/in_a_frame")
  end

  def loading
    preview(loading: true, label: "Loading")
  end

  def disabled
    preview(disabled: true, label: "Disabled")
  end

  private
    def preview(variant: "primary", size: "default", loading: false,
                disabled: false, label: "Button", aria: nil)
      render_with_template(template: "button_preview/preview",
        locals: { variant:, size:, loading:, disabled:, label:, aria: })
    end
end
