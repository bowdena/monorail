# Previews for the accordion component.
#
# Each scenario renders through render_accordion
# (Gesso::Components::AccordionHelper) via the shared accordion_preview/preview
# template.
#
# @label Accordion
class AccordionPreview < Lookbook::Preview
  FAQS = [
    { label: "What is an NHS number?",
      body: "A unique 10-digit number used to identify you across the NHS.",
      open: true },
    { label: "How do I find my NHS number?",
      body: "It is on any letter the NHS has sent you, or ask your GP." },
    { label: "Is my data secure?",
      body: "Yes — access is logged and governed by NHS data policies." }
  ].freeze

  # Usage rules: [Accordion design guidance](/lookbook/pages/components/accordion)
  #
  # @param multiple toggle
  def playground(multiple: false)
    preview(id: "faq", items: FAQS, multiple:)
  end

  def default
    preview(id: "faq", items: FAQS)
  end

  def multiple
    preview(id: "faq", items: FAQS, multiple: true)
  end

  private
    def preview(id: "accordion", items: [], multiple: false, classes: nil)
      render_with_template(template: "accordion_preview/preview",
        locals: { id:, items:, multiple:, classes: })
    end
end
