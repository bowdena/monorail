require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body is
# parsed with Capybara.string so DOM matchers can query it. The dialog is
# closed in the rendered markup, so matchers use visible: :all. Browser
# behaviour (open/close/backdrop) is covered by the header system spec,
# which exercises the same drawer controller this sheet uses.
RSpec.describe "Sheet component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/sheet/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a native dialog shell with the drawer panel wiring" do
    page = render_preview("default")
    expect(page).to have_css(
      "dialog#demo-sheet.sheet[data-drawer-target='panel']", visible: :all
    )
    expect(page).to have_css(
      "dialog[data-action='click->drawer#backdropClick']", visible: :all
    )
  end

  it "labels the dialog from aria_label" do
    page = render_preview("default")
    expect(page).to have_css(
      "dialog[aria-label='Demo sheet']", visible: :all
    )
  end

  it "renders the caller's block as the panel body" do
    page = render_preview("default")
    expect(page).to have_text("Sheet body content.")
  end

  it "places the sheet on the right by default" do
    page = render_preview("default")
    expect(page).to have_css("dialog.sheet-right", visible: :all)
    expect(page).to have_no_css("dialog.sheet-left", visible: :all)
  end

  it "places the sheet on the left when side is left" do
    page = render_preview("left")
    expect(page).to have_css("dialog.sheet-left", visible: :all)
    expect(page).to have_no_css("dialog.sheet-right", visible: :all)
  end
end
