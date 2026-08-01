module Gesso::Components
  module CommandHelper
    # Renders the command component — a searchable, grouped command menu.
    # This is the public entry point; command is purely structural, so the
    # helper passes its locals straight to the partial.
    #
    #   render_command(groups: [...], placeholder: "Search…")
    def render_command(groups: [], placeholder: "Search…", empty: nil)
      render("gesso/components/command", groups:, placeholder:, empty:)
    end
  end
end
