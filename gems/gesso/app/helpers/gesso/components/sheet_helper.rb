module Gesso::Components
  module SheetHelper
    SIDES = %w[ right left ].freeze

    # Renders the sheet component — the positioned <dialog> shell. This is
    # the public entry point: it validates the side, then renders the
    # partial with the block as the panel contents (the caller supplies
    # the panel's own header and body). Render it inside a
    # [data-controller="drawer"] element alongside its trigger.
    #
    #   render_sheet(id: "notifications", aria_label: "Notifications") do
    #     # panel header + body
    #   end
    def render_sheet(id:, aria_label:, side: "right", classes: nil, &block)
      unless SIDES.include?(side)
        raise ArgumentError, "side must be one of #{SIDES.join(", ")}"
      end

      render("gesso/components/sheet",
        id:, aria_label:, side:, classes:, &block)
    end
  end
end
