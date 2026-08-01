# Previews for the avatar treatment.
#
# An avatar is an <img> plus utilities, written inline (no partial or
# helper); the scenario renders the documented markup so the design docs
# can embed a live example.
#
# @label Avatar
class AvatarPreview < Lookbook::Preview
  # Usage rules: [Avatar design guidance](/lookbook/pages/components/avatar)
  def default
    render_with_template(template: "avatar_preview/default")
  end
end
