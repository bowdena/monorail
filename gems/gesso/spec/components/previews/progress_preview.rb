# Previews for the progress bar.
#
# A progress bar is a track and fill built from utilities, written
# inline (no partial or helper); the scenario renders the documented
# markup so the design docs can embed a live example.
#
# @label Progress
class ProgressPreview < Lookbook::Preview
  # Usage rules: [Progress design guidance](/lookbook/pages/components/progress)
  def default
    render_with_template(template: "progress_preview/default")
  end
end
