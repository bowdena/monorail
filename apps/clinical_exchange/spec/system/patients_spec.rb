require "system_helper"

# Nothing serves iPM in the test environment, so a search here always
# takes the fallback path — which makes this the end-to-end cover for a
# clinician searching while the replica is unreachable.
RSpec.describe "Patient lookup", type: :system do
  it "searches from the form" do
    visit patients_path

    fill_in "urn", with: "0700003"
    click_button "Search"

    expect(page).to have_css("[role=alert]", text: "iPM is unavailable")
    expect(page).to have_css("[role=alert]", text: "No saved patient matches")
  end

  it "finds a patient kept from an earlier lookup" do
    create(:patient, urn: "0700003", first_name: "Tori", last_name: "Judd")

    visit patients_path
    fill_in "urn", with: "0700003"
    click_button "Search"

    expect(page).to have_css("[role=alert]", text: "iPM is unavailable")
    expect(page).to have_css("table.table td", text: "Tori Judd")
  end

  it "leaves no patient identifier in the url" do
    visit patients_path

    fill_in "urn", with: "0700003"
    click_button "Search"

    expect(page).to have_css("[role=alert]")
    expect(page.current_url).not_to include("0700003")
  end
end
