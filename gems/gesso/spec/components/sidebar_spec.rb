require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it. Collapse
# behaviour lives in the system spec; this asserts structure only.
RSpec.describe "Sidebar component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/sidebar/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders the app name and a nav item per entry" do
    page = render_preview("default")
    expect(page).to have_css("aside#main-sidebar.sidebar")
    expect(page).to have_text("NHS App")
    expect(page).to have_css("nav ul li", count: 5)
  end

  it "links each nav item to its path" do
    page = render_preview("default")
    expect(page).to have_css('nav a[href="/patients"]', text: "Patients")
    expect(page).to have_css('nav a[href="/settings"]', text: "Settings")
  end

  it "renders the theme toggle in the footer" do
    page = render_preview("default")
    expect(page).to have_css('footer button[data-controller="theme"]')
  end
end
