# Previews for the sheet component partial.
#
# @label Sheet
class SheetPreview < Lookbook::Preview
  # Usage rules: [Sheet design guidance](/lookbook/pages/components/sheet)
  def default
    render_with_template(
      template: "sheet_preview/preview", locals: { side: "right" }
    )
  end

  # Opens from the left edge.
  def left
    render_with_template(
      template: "sheet_preview/preview", locals: { side: "left" }
    )
  end
end
