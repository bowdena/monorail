require "rails_helper"

RSpec.describe "Support page", type: :system do
  it "renders email support card" do
    visit "/support"

    expect(page).to have_text("Support")
    expect(page).to have_text("Email Support")
  end
end
