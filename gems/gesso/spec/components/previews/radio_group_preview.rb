# Previews for the radio group.
#
# A radio group is a fieldset of native radios styled by basecoat's
# `input` class, written inline (no partial or helper); the scenario
# renders the documented markup so the design docs can embed a live
# example.
#
# @label Radio group
class RadioGroupPreview < Lookbook::Preview
  # Usage rules: [Radio group design guidance](/lookbook/pages/components/radio_group)
  def default
    render_with_template(template: "radio_group_preview/default")
  end
end
