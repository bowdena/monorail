require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Command component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/command/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a search input in the header" do
    page = render_preview("default")
    expect(page).to have_css("div.command > header input")
  end

  it "renders group headings" do
    page = render_preview("default")
    expect(page).to have_css("[role='heading']", text: "Navigation")
    expect(page).to have_css("[role='heading']", text: "Actions")
  end

  it "renders menu items within groups" do
    page = render_preview("default")
    expect(page).to have_css(
      "[role='group'] [role='menuitem']", text: "Dashboard"
    )
    expect(page).to have_css(
      "[role='group'] [role='menuitem']", text: "New patient"
    )
  end

  it "renders a data-empty attribute for the empty state" do
    page = render_preview("custom_empty")
    expect(page).to have_css(
      "[role='menu'][data-empty='Nothing here yet.']"
    )
  end
end
