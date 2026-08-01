require "rails_helper"

# Unit spec for the header view helper. render_header computes the unread
# notification count/label and renders the gesso/components/header partial;
# here we call it directly and assert on the HTML it returns. The
# notification drawer is a closed dialog, so matchers use visible: :all.
RSpec.describe Gesso::Components::HeaderHelper, type: :helper do
  it "renders the user identity and initials avatar" do
    html = helper.render_header(title: "Dashboard", user_name: "Jane Smith",
      user_initials: "JS", user_email: "jane.smith@nhs.net")
    page = Capybara.string(html)
    expect(page).to have_css("header#main-header")
    expect(page).to have_css("span.user-avatar", text: "JS")
    expect(page).to have_text("Jane Smith")
    expect(page).to have_text("jane.smith@nhs.net")
  end

  it "badges the bell with the unread count" do
    html = helper.render_header(notifications: [
      { title: "A", message: "m", type: "info", read: false, time: "1m" },
      { title: "B", message: "m", type: "info", read: true,  time: "2m" },
      { title: "C", message: "m", type: "info", read: false, time: "3m" }
    ])
    expect(Capybara.string(html))
      .to have_css("span.notification-badge", text: "2")
  end

  it "caps the unread badge at 9+" do
    notifications = Array.new(10) do |i|
      { title: "N#{i}", message: "m", type: "info", read: false, time: "1m" }
    end
    html = helper.render_header(notifications:)
    expect(Capybara.string(html))
      .to have_css("span.notification-badge", text: "9+")
  end

  it "shows the empty state and no badge when there are no notifications" do
    html = helper.render_header(notifications: [])
    page = Capybara.string(html)
    expect(page).to have_text("No notifications yet")
    expect(page).to have_no_css("span.notification-badge")
  end

  it "renders the title as an h1" do
    html = helper.render_header(title: "Patients")
    expect(Capybara.string(html)).to have_css("h1", text: "Patients")
  end

  it "omits the search field when show_search is false" do
    html = helper.render_header(show_search: false)
    expect(Capybara.string(html)).to have_no_css("input[type='search']")
  end
end
