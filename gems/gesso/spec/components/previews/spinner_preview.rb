# Previews for the spinner.
#
# A spinner is the loader-circle lucide icon with `animate-spin`,
# written inline (no partial or helper); the scenario renders the
# documented markup so the design docs can embed a live example.
#
# @label Spinner
class SpinnerPreview < Lookbook::Preview
  # Usage rules: [Spinner design guidance](/lookbook/pages/components/spinner)
  def default
    render_with_template(template: "spinner_preview/default")
  end
end
