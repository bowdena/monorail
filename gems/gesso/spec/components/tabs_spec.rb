require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Tabs component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/tabs/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders the aria tab markup basecoat wires up" do
    page = render_preview("default")
    expect(page).to have_css('.tabs [role="tablist"]')
    expect(page).to have_css('[role="tab"][aria-controls="demo-panel-0"]')
  end

  it "selects the first tab and hides the rest initially" do
    page = render_preview("default")
    expect(page).to have_css('#demo-tab-0[aria-selected="true"]')
    expect(page).to have_css("#demo-panel-1[hidden]", visible: :all)
  end
end
