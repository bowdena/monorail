# Previews for the card component.
#
# Each scenario renders through render_card (Gesso::Components::CardHelper) via
# the shared card_preview/preview template.
#
# @label Card
class CardPreview < Lookbook::Preview
  # Usage rules: [Card design guidance](/lookbook/pages/components/card)
  #
  # @param id text
  # @param title text
  # @param description text
  # @param footer text
  # @param body text
  def playground(id: "", title: "Card title", description: "Card description",
                 footer: "Card footer", body: "Card content goes here.")
    preview(id:, title:, description:, footer:, body:)
  end

  def default
    preview(body: "A simple card with body content only.")
  end

  def with_header
    preview(title: "Patient details",
            description: "NHS number 943 476 5919",
            body: "Header with a title and description.")
  end

  def with_footer
    preview(title: "Confirm", footer: "Last updated today",
            body: "Card with a footer.")
  end

  # A richer header (an icon beside the title) passed via the header slot,
  # with an id on the card element.
  def custom_header
    render_with_template(template: "card_preview/custom_header")
  end

  private
    def preview(id: nil, title: nil, description: nil, footer: nil, body: nil)
      render_with_template(template: "card_preview/preview",
        locals: { id:, title:, description:, footer:, body: })
    end
end
