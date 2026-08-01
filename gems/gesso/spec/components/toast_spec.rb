require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Toast component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/toast/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a success toast for a notice flash" do
    page = render_preview("success")
    expect(page).to have_css(
      "#toaster .toast[data-category='success'][role='status']"
    )
    expect(page).to have_css(".toast p", text: "Your changes were saved.")
  end

  it "renders an error toast with role=alert for an alert flash" do
    page = render_preview("error")
    expect(page).to have_css(
      "#toaster .toast[data-category='error'][role='alert']"
    )
    expect(page).to have_css(
      ".toast p", text: "Something went wrong. Please try again."
    )
  end

  it "renders an info toast for an info flash" do
    page = render_preview("info")
    expect(page).to have_css(
      "#toaster .toast[data-category='info'][role='status']"
    )
    expect(page).to have_css(".toast p", text: "A new version is available.")
  end

  it "renders multiple toasts for multiple flash messages" do
    page = render_preview("multiple")
    expect(page).to have_css(".toast", count: 2)
    expect(page).to have_css(".toast[data-category='success']")
    expect(page).to have_css(".toast[data-category='warning']")
  end

  it "renders an auto-dismissing toast with a 3s window" do
    page = render_preview("auto_dismissing")
    expect(page).to have_css(".toast[data-duration='3000']")
  end

  it "renders a persistent toast that never auto-dismisses" do
    page = render_preview("persistent")
    expect(page).to have_css(".toast[data-duration='-1']")
  end

  it "renders the playground toast from its defaults" do
    page = render_preview("playground")
    expect(page).to have_css(".toast[data-category='success']")
    expect(page).to have_css(".toast footer button[aria-label='Dismiss']")
  end
end
