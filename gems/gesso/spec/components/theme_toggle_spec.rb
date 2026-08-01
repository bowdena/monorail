require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it. The
# theme-cycling behaviour lives in the system spec; this asserts the
# rendered control and its three icon targets only.
RSpec.describe "Theme toggle component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/theme_toggle/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a theme-controller button with an accessible label" do
    page = render_preview("default")
    expect(page).to have_css('button[data-controller="theme"][aria-label="Toggle theme"]')
  end

  it "renders sun, moon and monitor icon targets" do
    page = render_preview("default")
    expect(page).to have_css('[data-theme-target="sun"]', visible: :all)
    expect(page).to have_css('[data-theme-target="moon"]', visible: :all)
    expect(page).to have_css('[data-theme-target="monitor"]')
  end
end
