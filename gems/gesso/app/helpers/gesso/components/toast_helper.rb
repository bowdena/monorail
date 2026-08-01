module Gesso::Components
  module ToastHelper
    # Rails flash type → basecoat toast category.
    CATEGORIES = {
      "notice"  => "success",
      "alert"   => "error",
      "error"   => "error",
      "info"    => "info",
      "warning" => "warning"
    }.freeze

    # Toast category → leading icon (an svg in icons/).
    ICONS = {
      "success" => "check-circle",
      "error"   => "x-circle",
      "info"    => "info",
      "warning" => "alert-triangle"
    }.freeze

    # Renders the toaster with one toast per flash message. This is the
    # public entry point: it maps each flash type to a category, role,
    # icon and auto-dismiss duration so the partial stays pure markup.
    # Unknown flash types fall back to the info category. Renders nothing
    # when the flash is empty.
    #
    #   render_toast(flash: flash)
    #
    # By default error toasts persist (the reader closes them with the
    # dismiss button) and everything else auto-dismisses after 3 s.
    # auto_dismiss overrides this for the whole call:
    #   nil   (default) - errors persist, everything else dismisses
    #   true            - everything dismisses (errors 5 s, else 3 s)
    #   false           - everything persists
    def render_toast(flash: {}, auto_dismiss: nil)
      toasts = flash.map do |type, message|
        category = CATEGORIES.fetch(type.to_s, "info")

        {
          message:,
          category:,
          role: (category == "error") ? "alert" : "status",
          icon: ICONS.fetch(category, "info"),
          duration: duration_for(category, auto_dismiss:)
        }
      end

      render("gesso/components/toast", toasts:)
    end

    private
      # Auto-dismiss window in ms; -1 means the toast never auto-dismisses
      # and must be closed with the dismiss button.
      def duration_for(category, auto_dismiss:)
        case auto_dismiss
        when true  then (category == "error") ? 5000 : 3000
        when false then -1
        else (category == "error") ? -1 : 3000
        end
      end
  end
end
