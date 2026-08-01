require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body is
# parsed with Capybara.string so DOM matchers can query it. The dialog is
# closed in the rendered markup, so matchers use visible: :all. Browser
# behaviour (open/close/backdrop) lives in the system spec.
RSpec.describe "Dialog component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/dialog/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a native dialog shell with the drawer panel wiring" do
    page = render_preview("default")
    expect(page).to have_css(
      "dialog#demo-dialog.dialog[data-drawer-target='panel']", visible: :all
    )
    expect(page).to have_css(
      "dialog[data-action='click->drawer#backdropClick']", visible: :all
    )
  end

  it "labels the dialog from its title and description" do
    page = render_preview("default")
    expect(page).to have_css(
      "dialog[aria-labelledby='demo-dialog-title']" \
      "[aria-describedby='demo-dialog-description']",
      visible: :all
    )
    expect(page).to have_css(
      "h2#demo-dialog-title", text: "Session expired", visible: :all
    )
    expect(page).to have_css(
      "p#demo-dialog-description", visible: :all
    )
  end

  it "renders a close button wired to the drawer controller" do
    page = render_preview("default")
    expect(page).to have_css(
      "button[aria-label='Close'][data-action='click->drawer#close']",
      visible: :all
    )
  end

  it "renders the caller's section body and footer actions" do
    page = render_preview("default")
    expect(page).to have_css("dialog section", visible: :all)
    expect(page).to have_css("dialog footer button", text: "Sign in", visible: :all)
    expect(page).to have_css("dialog footer button", text: "Cancel", visible: :all)
  end

  it "renders the long body for the scrollable scenario" do
    page = render_preview("scrollable")
    expect(page).to have_css(
      "dialog section p", text: "Paragraph 12", visible: :all
    )
  end
end
