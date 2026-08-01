require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body is
# parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Notification item component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/notification_item/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a success notification with its icon colour" do
    page = render_preview("success")
    expect(page).to have_css("svg.text-success")
    expect(page).to have_text("Report generated")
  end

  it "renders a warning notification with its icon colour" do
    expect(render_preview("warning")).to have_css("svg.text-warning")
  end

  it "renders an info notification with its icon colour" do
    expect(render_preview("info")).to have_css("svg.text-info")
  end

  it "mutes a read notification" do
    expect(render_preview("read")).to have_css("div.bg-muted\\/30")
  end

  it "renders the playground from its defaults" do
    page = render_preview("playground")
    expect(page).to have_css("svg.text-info")
    expect(page).to have_text("New version available")
  end
end
