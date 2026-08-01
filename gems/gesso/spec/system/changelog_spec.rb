require "rails_helper"

RSpec.describe "Changelog page", type: :system do
  it "renders at least one changelog entry" do
    visit "/changelog"

    expect(page).to have_css(".card")
    expect(page).to have_text("Changelog")
  end
end
