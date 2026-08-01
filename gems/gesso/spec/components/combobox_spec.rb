require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Combobox component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/combobox/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a trigger button with the selected option's label" do
    page = render_preview("default")
    expect(page).to have_css(
      "div.select > button[aria-haspopup='listbox']",
      text: "Ruby on Rails"
    )
  end

  it "renders the trigger with placeholder when nothing is selected" do
    page = render_preview("no_selection")
    expect(page).to have_css(
      "div.select > button", text: "Select framework…"
    )
  end

  it "renders options in a listbox popover" do
    page = render_preview("default")
    expect(page).to have_css(
      "div[data-popover] [role='listbox'] [role='option']",
      text: "Django"
    )
  end

  it "marks the selected option with aria-selected" do
    page = render_preview("default")
    expect(page).to have_css(
      "[role='option'][aria-selected='true']", text: "Ruby on Rails"
    )
  end

  it "renders no other option with aria-selected" do
    page = render_preview("default")
    expect(page).to have_no_css(
      "[role='option'][aria-selected='true']", text: "Django"
    )
  end

  it "renders a search filter by default" do
    page = render_preview("default")
    expect(page).to have_css(
      "div[data-popover] header input[role='combobox']"
    )
  end

  it "omits the search filter when searchable is false" do
    page = render_preview("not_searchable")
    expect(page).to have_no_css(
      "div[data-popover] header input[role='combobox']"
    )
  end
end
