module Gesso::Components
  module AlertHelper
    VARIANTS = %w[ default destructive warning critical info ].freeze

    # Renders the alert component. This is the public entry point: it
    # validates the variant and hands the partial the variant basecoat
    # reads from a data attribute, so the partial stays pure markup.
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
        variant: basecoat_value(variant),
        icon:, title:, classes:, &block)
    end

    private
      # basecoat styles the default variant through the absence of the
      # attribute, so "default" is sent as nil and the partial drops it.
      def basecoat_value(variant)
        variant unless variant == "default"
      end
  end
end
