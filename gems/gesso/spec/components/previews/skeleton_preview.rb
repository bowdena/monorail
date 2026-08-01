# Previews for the skeleton placeholder.
#
# A skeleton is `animate-pulse` plus the `accent` token, written inline
# (no partial or helper); the scenario renders the documented markup so
# the design docs can embed a live example.
#
# @label Skeleton
class SkeletonPreview < Lookbook::Preview
  # Usage rules: [Skeleton design guidance](/lookbook/pages/components/skeleton)
  def default
    render_with_template(template: "skeleton_preview/default")
  end
end
