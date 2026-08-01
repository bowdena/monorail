require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Card component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/card/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a card with a body section" do
    page = render_preview("default")
    expect(page).to have_css("div.card section")
  end

  it "renders the header title and description" do
    page = render_preview("with_header")
    expect(page).to have_css("div.card header h2", text: "Patient details")
    expect(page).to have_text("NHS number 943 476 5919")
  end

  it "renders the footer when given" do
    page = render_preview("with_footer")
    expect(page).to have_css("div.card footer", text: "Last updated today")
  end

  it "omits the header and footer when not given" do
    page = render_preview("default")
    expect(page).to have_no_css("div.card header")
    expect(page).to have_no_css("div.card footer")
  end

  it "renders a custom header and an id" do
    page = render_preview("custom_header")
    expect(page).to have_css("div.card#patient-1234567 header svg")
    expect(page).to have_css("div.card header h2", text: "Patient details")
  end
end
