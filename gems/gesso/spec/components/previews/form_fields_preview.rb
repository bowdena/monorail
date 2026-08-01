# Previews for the basic form fields: input, textarea, label, select
# and switch.
#
# Each is a native element carrying its basecoat class, written inline
# (no partial or helper); the scenarios render the documented markup so
# the design docs can embed live examples per field.
#
# @label Form fields
class FormFieldsPreview < Lookbook::Preview
  # Usage rules: [Form fields design guidance](/lookbook/pages/components/form_fields)
  def input
    render_with_template(template: "form_fields_preview/input")
  end

  def textarea
    render_with_template(template: "form_fields_preview/textarea")
  end

  def label
    render_with_template(template: "form_fields_preview/label")
  end

  def select
    render_with_template(template: "form_fields_preview/select")
  end

  def switch
    render_with_template(template: "form_fields_preview/switch")
  end
end
