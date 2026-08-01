require "rails_helper"

# Unit spec for the notification item view helper.
# render_notification_item maps the type to an icon + colour and the read
# state to its classes, then renders the partial; here we call it
# directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::NotificationItemHelper, type: :helper do
  it "maps a success type to the success icon and colour" do
    html = helper.render_notification_item(notification: {
      type: "success", title: "T", message: "m", time: "1m", read: false })
    expect(Capybara.string(html)).to have_css("svg.text-success")
  end

  it "maps a warning type to the warning icon and colour" do
    html = helper.render_notification_item(notification: {
      type: "warning", title: "T", message: "m", time: "1m", read: false })
    expect(Capybara.string(html)).to have_css("svg.text-warning")
  end

  it "falls back to the info icon and colour for an unknown type" do
    html = helper.render_notification_item(notification: {
      type: "anything-else", title: "T", message: "m", time: "1m", read: false })
    expect(Capybara.string(html)).to have_css("svg.text-info")
  end

  it "renders the title, message and time" do
    html = helper.render_notification_item(notification: {
      type: "info", title: "New version", message: "Update available.",
      time: "5m ago", read: false })
    page = Capybara.string(html)
    expect(page).to have_text("New version")
    expect(page).to have_text("Update available.")
    expect(page).to have_text("5m ago")
  end

  it "tints the container for an unread notification" do
    html = helper.render_notification_item(notification: {
      type: "info", title: "T", message: "m", time: "1m", read: false })
    expect(Capybara.string(html)).to have_css("div.border-primary\\/20")
  end

  it "mutes the container and title for a read notification" do
    html = helper.render_notification_item(notification: {
      type: "info", title: "T", message: "m", time: "1m", read: true })
    page = Capybara.string(html)
    expect(page).to have_css("div.bg-muted\\/30")
    expect(page).to have_css("p.text-muted-foreground", text: "T")
  end
end
