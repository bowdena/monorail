require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Stat card component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/stat_card/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders the title and value inside a card" do
    page = render_preview("default")
    expect(page).to have_css("div.card")
    expect(page).to have_text("Total patients")
    expect(page).to have_css(".stat-card-value", text: "1,284")
  end

  it "maps a positive change to a success badge" do
    page = render_preview("positive")
    expect(page).to have_css("span.badge.badge-success", text: "+12%")
  end

  it "maps a negative change to a destructive badge" do
    page = render_preview("negative")
    expect(page).to have_css("span.badge.badge-destructive", text: "-4%")
  end

  it "maps a neutral change to a secondary badge" do
    page = render_preview("neutral")
    expect(page).to have_css("span.badge.badge-secondary", text: "0%")
  end

  it "renders a leading icon when given" do
    page = render_preview("with_icon")
    expect(page).to have_css("svg")
  end

  it "omits the change badge when no change is given" do
    page = render_preview("default")
    expect(page).to have_no_css("span.badge")
  end
end
