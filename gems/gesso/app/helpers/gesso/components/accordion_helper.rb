module Gesso::Components
  module AccordionHelper
    # Renders the accordion component — a stack of native <details>
    # disclosure sections. This is the public entry point; accordion is
    # purely structural, so the helper passes its locals straight to the
    # partial.
    #
    #   render_accordion(id: "faq", items: [...])
    def render_accordion(id: "accordion", items: [], multiple: false,
                         classes: nil)
      render("gesso/components/accordion", id:, items:, multiple:, classes:)
    end
  end
end
