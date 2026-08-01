# Previews for the toast component.
#
# Each scenario renders through render_toast (Gesso::Components::ToastHelper)
# via the shared toast_preview/preview template.
#
# @label Toast
class ToastPreview < Lookbook::Preview
  # Usage rules: [Toast design guidance](/lookbook/pages/components/toast)
  #
  # @param flash_type select [notice, alert, info, warning]
  # @param message text
  # @param auto_dismiss select [default, always, never]
  def playground(flash_type: "notice",
                 message: "Your changes were saved.",
                 auto_dismiss: "default")
    preview({ flash_type => message }, auto_dismiss: override(auto_dismiss))
  end

  # The category examples below pin auto_dismiss: false so they stay on
  # screen for inspection; auto_dismissing and playground keep the real
  # dismiss behaviour.
  def success
    preview({ "notice" => "Your changes were saved." }, auto_dismiss: false)
  end

  def error
    preview({ "alert" => "Something went wrong. Please try again." })
  end

  def info
    preview({ "info" => "A new version is available." }, auto_dismiss: false)
  end

  def warning
    preview({ "warning" => "Your session will expire in 5 minutes." },
      auto_dismiss: false)
  end

  # A toast that auto-dismisses after 3 seconds (the default for
  # non-error toasts).
  def auto_dismissing
    preview({ "notice" => "Saved — this dismisses itself after 3 seconds." })
  end

  # A toast that stays until dismissed. Errors persist by default;
  # auto_dismiss: false forces it for any toast.
  def persistent
    preview({ "info" => "This stays until you dismiss it." },
      auto_dismiss: false)
  end

  # Multiple flash messages rendered together.
  def multiple
    preview({
      "notice"  => "Profile updated.",
      "warning" => "Email not verified."
    }, auto_dismiss: false)
  end

  # Every flash type rendered together — embedded in the design docs.
  def variants
    render_with_template(template: "toast_preview/variants")
  end

  private
    def preview(flash, auto_dismiss: nil)
      render_with_template(template: "toast_preview/preview",
        locals: { flash:, auto_dismiss: })
    end

    # Maps the playground's auto_dismiss select to the tri-state the
    # helper expects.
    def override(choice)
      { "always" => true, "never" => false }.fetch(choice, nil)
    end
end
