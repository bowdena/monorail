module Gesso::Components
  module ButtonHelper
    VARIANTS = %w[ default primary secondary outline ghost link
                   destructive warning info ].freeze
    SIZES = %w[ default sm lg icon ].freeze

    # Renders the button component. This is the public entry point: it
    # owns the class composition and hands the partial a ready-made
    # button_class so the partial stays pure markup.
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
        button_class: button_class(variant:, size:),
        type:, loading:, disabled:, classes:, &block)
    end

    private
      # basecoat: "btn" is the base/default; size and variant are
      # suffixes, combined as "btn-<size>-<variant>" when both are
      # non-default.
      def button_class(variant:, size:)
        size_segment    = (size == "default") ? nil : "btn-#{size}"
        variant_segment = (variant == "default") ? nil : variant

        case
        when size_segment && variant_segment then "#{size_segment}-#{variant_segment}"
        when size_segment then size_segment
        when variant_segment then "btn-#{variant_segment}"
        else "btn"
        end
      end
  end
end
