# Previews for the separator.
#
# A separator is the `border` token applied inline (no partial or
# helper); the scenarios render the documented horizontal and vertical
# forms so the design docs can embed live examples.
#
# @label Separator
class SeparatorPreview < Lookbook::Preview
  # Usage rules: [Separator design guidance](/lookbook/pages/components/separator)
  def horizontal
    render_with_template(template: "separator_preview/horizontal")
  end

  def vertical
    render_with_template(template: "separator_preview/vertical")
  end
end
