# Previews for the dialog component partial.
#
# @label Dialog
class DialogPreview < Lookbook::Preview
  # Usage rules: [Dialog design guidance](/lookbook/pages/components/dialog)
  def default
    render_with_template(
      template: "dialog_preview/preview", locals: { long: false }
    )
  end

  # A long body to show the section scrolling natively within the dialog.
  def scrollable
    render_with_template(
      template: "dialog_preview/preview", locals: { long: true }
    )
  end
end
