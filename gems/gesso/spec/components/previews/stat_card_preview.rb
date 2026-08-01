# Previews for the stat card component.
#
# Each scenario renders through render_stat_card
# (Gesso::Components::StatCardHelper) via the shared stat_card_preview/preview
# template.
#
# @label Stat Card
class StatCardPreview < Lookbook::Preview
  # Usage rules: [Stat card design guidance](/lookbook/pages/components/stat_card)
  def default
    preview(title: "Total patients", value: "1,284")
  end

  # Every change type rendered together — embedded in the design docs.
  def variants
    render_with_template(template: "stat_card_preview/variants")
  end

  def positive
    preview(title: "Active referrals", value: "342",
            change: "+12%", change_type: "positive")
  end

  def negative
    preview(title: "Overdue tasks", value: "18",
            change: "-4%", change_type: "negative")
  end

  def neutral
    preview(title: "Beds available", value: "56",
            change: "0%", change_type: "neutral")
  end

  def with_icon
    preview(title: "Total patients", value: "1,284",
            change: "+12%", change_type: "positive", icon: "users")
  end

  private
    def preview(title: nil, value: nil, change: nil,
                change_type: "neutral", icon: nil)
      render_with_template(template: "stat_card_preview/preview",
        locals: { title:, value:, change:, change_type:, icon: })
    end
end
