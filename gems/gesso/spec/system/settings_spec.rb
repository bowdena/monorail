require "rails_helper"

RSpec.describe "Settings page", type: :system do
  before { visit "/settings" }

  it "switches between Profile and Preferences tabs" do
    expect(page).to have_text("Display Name")

    click_button "Preferences"

    expect(page).to have_text("Theme")
    expect(page).not_to have_text("Display Name")
  end
end
