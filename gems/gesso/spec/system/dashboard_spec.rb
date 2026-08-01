require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  before { visit "/" }

  it "renders stat cards and quick links" do
    expect(page).to have_css(".card")
    expect(page).to have_text("Dashboard")
  end

  it "renders the stats as stat cards with their values" do
    expect(page).to have_css(".stat-card", count: 4)
    expect(page).to have_css(".stat-card-value", text: "2,847")
  end

  it "colours each trend by its meaning" do
    # A rise in patients reads as positive (success), a backlog of
    # high-priority reviews as negative (destructive), the rest neutral.
    expect(page).to have_css(".stat-card .badge[data-variant='success']", text: "+12 this week")
    expect(page).to have_css(
      ".stat-card .badge[data-variant='destructive']", text: "2 high priority"
    )
    expect(page).to have_css(".stat-card .badge[data-variant='secondary']", count: 2)
  end
end
