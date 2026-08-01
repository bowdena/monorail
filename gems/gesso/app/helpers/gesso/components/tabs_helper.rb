module Gesso::Components
  module TabsHelper
    # Renders the tabs component — ARIA tab markup that basecoat's bundled
    # JS auto-wires. This is the public entry point; tabs is purely
    # structural, so the helper passes its locals straight to the partial.
    #
    #   render_tabs(id: "episode", tabs: [...])
    def render_tabs(id: "tabs", tabs: [])
      render("gesso/components/tabs", id:, tabs:)
    end
  end
end
