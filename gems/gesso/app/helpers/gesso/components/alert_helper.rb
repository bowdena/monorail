module Gesso::Components
  module AlertHelper
    VARIANTS = %w[ default destructive warning critical info ].freeze

    # Renders the alert component. This is the public entry point: it
    # validates the variant and hands the partial a ready-made
    # alert_class so the partial stays pure markup.
    #
    #   render_alert(variant: "warning", title: "Caution") { "..." }
    #
    # The block is the alert body.
    def render_alert(variant: "default", icon: nil, title: nil,
                     classes: nil, &block)
      unless VARIANTS.include?(variant)
        raise ArgumentError, "variant must be one of #{VARIANTS.join(", ")}"
      end

      render("gesso/components/alert",
        alert_class: alert_class(variant:),
        icon:, title:, classes:, &block)
    end

    private
      # basecoat ships "alert" (default) and "alert-destructive"; the
      # clinical variants layer a colour modifier on the base "alert".
      def alert_class(variant:)
        case variant
        when "destructive" then "alert-destructive"
        when "default"     then "alert"
        else "alert alert-#{variant}"
        end
      end
  end
end
