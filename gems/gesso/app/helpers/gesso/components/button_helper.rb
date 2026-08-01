module Gesso::Components
  module ButtonHelper
    VARIANTS = %w[ default primary secondary outline ghost link
                   destructive warning info ].freeze
    SIZES = %w[ default xs sm lg icon icon-xs icon-sm icon-lg ].freeze

    # Renders the button component. This is the public entry point: it
    # validates the options and hands the partial the variant and size
    # basecoat reads from data attributes, so the partial stays pure
    # markup.
    #
    #   render_button(variant: "primary", size: "sm") { "Save" }
    #
    # The block is the button label.
    def render_button(variant: "primary", size: "default", type: "button",
                      loading: false, disabled: false, classes: nil, &block)
      unless VARIANTS.include?(variant)
        raise ArgumentError, "variant must be one of #{VARIANTS.join(", ")}"
      end

      unless SIZES.include?(size)
        raise ArgumentError, "size must be one of #{SIZES.join(", ")}"
      end

      render("gesso/components/button",
        variant: basecoat_value(variant), size: basecoat_value(size),
        type:, loading:, disabled:, classes:, &block)
    end

    private
      # basecoat styles the default variant and size through the absence
      # of the attribute, so "default" is sent as nil and the partial
      # drops it.
      def basecoat_value(value)
        value unless value == "default"
      end
  end
end
