require "rails_helper"

# Unit spec for the theme toggle view helper. render_theme_toggle builds
# the icon button inline (this atomic component has no partial); here we
# call it directly and assert on the HTML it returns. The theme-cycling
# behaviour lives in the system spec.
RSpec.describe Gesso::Components::ThemeToggleHelper, type: :helper do
  it "renders a theme-controller button with an accessible label" do
    html = helper.render_theme_toggle
    expect(Capybara.string(html)).to have_css(
      'button[data-controller="theme"][aria-label="Toggle theme"]')
  end

  it "wires the cycle action" do
    html = helper.render_theme_toggle
    expect(Capybara.string(html))
      .to have_css('button[data-action="click->theme#cycle"]')
  end

  it "renders sun, moon and monitor icon targets" do
    page = Capybara.string(helper.render_theme_toggle)
    expect(page).to have_css('[data-theme-target="sun"]', visible: :all)
    expect(page).to have_css('[data-theme-target="moon"]', visible: :all)
    expect(page).to have_css('[data-theme-target="monitor"]')
  end
end
