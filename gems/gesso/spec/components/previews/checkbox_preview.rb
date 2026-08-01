# Previews for the checkbox field.
#
# A checkbox is a native input styled by basecoat's `input` class,
# written inline (no partial or helper); the scenario renders the
# documented markup so the design docs can embed a live example.
#
# @label Checkbox
class CheckboxPreview < Lookbook::Preview
  # Usage rules: [Checkbox design guidance](/lookbook/pages/components/checkbox)
  def default
    render_with_template(template: "checkbox_preview/default")
  end
end
