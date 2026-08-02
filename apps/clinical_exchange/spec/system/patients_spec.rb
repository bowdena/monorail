require "system_helper"

RSpec.describe "Patient lookup", type: :system do
  it "searches from the form" do
    visit patients_path

    fill_in "urn", with: "0700003"
    click_button "Search"

    expect(page).to have_css("[role=alert]", text: "No patient found")
  end
end
