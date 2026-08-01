# Previews for the badge component.
#
# Badges are written inline (no partial or helper); the scenario renders
# the documented markup so the design docs can embed a live example.
#
# @label Badge
class BadgePreview < Lookbook::Preview
  # Usage rules: [Badge design guidance](/lookbook/pages/components/badge)
  def variants
    render_with_template(template: "badge_preview/variants")
  end
end
