module Gesso::Components
  module StatCardHelper
    CHANGE_TYPES = %w[ positive negative neutral ].freeze

    # Renders the stat card component. This is the public entry point: it
    # validates change_type and hands the partial a ready-made badge_class
    # so the partial stays pure markup.
    #
    #   render_stat_card(title: "Open referrals", value: 42,
    #                    change: "+12%", change_type: "positive")
    def render_stat_card(title: nil, value: nil, change: nil,
                         change_type: "neutral", icon: nil, classes: nil)
      unless CHANGE_TYPES.include?(change_type)
        raise ArgumentError,
          "change_type must be one of #{CHANGE_TYPES.join(", ")}"
      end

      render("gesso/components/stat_card",
        title:, value:, change:,
        badge_class: badge_class(change_type:),
        icon:, classes:)
    end

    private
      # change_type maps to a badge variant: positive -> success,
      # negative -> destructive, neutral -> secondary.
      def badge_class(change_type:)
        case change_type
        when "positive" then "badge badge-success"
        when "negative" then "badge badge-destructive"
        else "badge badge-secondary"
        end
      end
  end
end
