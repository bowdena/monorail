require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it. Browser
# behaviour (opening/closing the notification drawer) lives in the
# system spec; this asserts the rendered structure only.
RSpec.describe "Header component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/header/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders the user identity and initials avatar" do
    page = render_preview("default")
    expect(page).to have_css("header#main-header")
    expect(page).to have_css("span.user-avatar", text: "JS")
    expect(page).to have_text("Jane Smith")
    expect(page).to have_text("jane.smith@nhs.net")
  end

  it "renders the notification drawer with an unread badge" do
    page = render_preview("default")
    expect(page).to have_css('[data-controller="drawer"] dialog.notification-drawer', visible: :all)
    # two of the three stub notifications are unread
    expect(page).to have_css("span.notification-badge", text: "2")
  end

  it "shows the empty state and no badge when there are no notifications" do
    page = render_preview("no_notifications")
    expect(page).to have_text("No notifications yet", normalize_ws: true)
    expect(page).to have_no_css("span.notification-badge")
  end
end
