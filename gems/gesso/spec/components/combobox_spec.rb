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

  it "renders the combobox input with the placeholder" do
    page = render_preview("no_selection")
    expect(page).to have_css(
      "div.combobox > input[role='combobox'][placeholder='Select framework…']"
    )
  end

  it "points the input at the listbox it controls" do
    page = render_preview("default")
    listbox_id = page.find("[role='listbox']")[:id]
    expect(page).to have_css(
      "input[role='combobox'][aria-controls='#{listbox_id}']"
    )
  end

  it "renders options in a listbox popover" do
    page = render_preview("default")
    expect(page).to have_css(
      "div[data-popover] [role='listbox'] [role='option'][data-value='django']",
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

  it "tracks the selection in a hidden input" do
    page = render_preview("default")
    expect(page).to have_css(
      "div.combobox > input[type='hidden'][name='framework'][value='rails']",
      visible: :all
    )
  end
end
