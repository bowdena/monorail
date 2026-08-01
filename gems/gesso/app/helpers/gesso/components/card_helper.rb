module Gesso::Components
  module CardHelper
    # Renders the card component — a bordered surface grouping related
    # content. This is the public entry point; card is purely structural,
    # so the helper passes its locals straight to the partial and renders
    # the block as the card body.
    #
    #   render_card(title: "Patient") { "Body" }
    #
    # For the common case pass title/description and the partial builds a
    # simple <header>. When a card needs a richer header (an icon, a
    # badge, custom layout), pass the pre-rendered header markup as
    # header: instead — it replaces the default header. id sets the id on
    # the card element.
    def render_card(title: nil, description: nil, footer: nil, classes: nil,
                    id: nil, header: nil, &block)
      render("gesso/components/card",
        title:, description:, footer:, classes:, id:, header:, &block)
    end
  end
end
