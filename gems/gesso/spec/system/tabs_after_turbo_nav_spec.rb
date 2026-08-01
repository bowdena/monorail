require "rails_helper"

# Regression: basecoat's JS only initialises components on DOMContentLoaded,
# which Turbo Drive does not re-fire. After navigating away via a sidebar
# link and back, the tabs are inert. A plain `visit` (hard load) hides this,
# so this spec navigates through Turbo-driven links.
RSpec.describe "Tabs after Turbo navigation", type: :system do
  it "still switches tabs after navigating away and back" do
    visit "/settings"
    expect(page).to have_text("Display Name")

    click_link "Patients"
    expect(page).to have_current_path("/patients")

    click_link "Settings"
    expect(page).to have_current_path("/settings")
    expect(page).to have_text("Display Name")

    click_button "Preferences"

    expect(page).to have_text("Theme")
    expect(page).not_to have_text("Display Name")
  end
end
