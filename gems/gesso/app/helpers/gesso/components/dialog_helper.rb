module Gesso::Components
  module DialogHelper
    # Renders the dialog component — a centred, blocking modal shell. This
    # is the public entry point; dialog is purely structural, so the
    # helper passes its locals straight to the partial and renders the
    # block as the dialog body/footer. Render it inside a
    # [data-controller="drawer"] element alongside its trigger.
    #
    #   render_dialog(id: "confirm", title: "Remove team?") do
    #     # <section> body + <footer> actions
    #   end
    def render_dialog(id:, title:, description: nil, close_label: "Close",
                      classes: nil, &block)
      render("gesso/components/dialog",
        id:, title:, description:, close_label:, classes:, &block)
    end
  end
end
