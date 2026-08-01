require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Accordion component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/accordion/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a details/summary per item with label and body" do
    page = render_preview("default")
    expect(page).to have_css("details", count: 3)
    expect(page).to have_css("details > summary", text: "What is an NHS number?")
    expect(page).to have_text("A unique 10-digit number")
  end

  it "renders a chevron icon in each summary" do
    page = render_preview("default")
    expect(page).to have_css("details > summary svg", count: 3)
  end

  it "gives every item a shared name so only one opens at a time" do
    page = render_preview("default")
    expect(page).to have_css('details[name="faq"]', count: 3)
  end

  it "opens the item flagged open by default" do
    page = render_preview("default")
    expect(page).to have_css("details[open]", count: 1)
  end

  it "omits the shared name when multiple sections may stay open" do
    page = render_preview("multiple")
    expect(page).to have_css("details", count: 3)
    expect(page).to have_no_css("details[name]")
  end
end
