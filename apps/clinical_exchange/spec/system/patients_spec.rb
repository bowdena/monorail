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

  # The forms sit outside the results frame precisely so a search cannot
  # throw the clinician back to the first tab with their criteria gone.
  it "stays on the advanced tab after searching" do
    create(:patient, first_name: "Tori", last_name: "Judd")

    visit patients_path
    click_button "Advanced search"

    within "#patients-panel-1" do
      fill_in "last_name", with: "jud"
      click_button "Search"
    end

    expect(page).to have_css("table.table td", text: "Tori Judd")
    expect(page).to have_css("[role=tab][aria-selected=true]",
      text: "Advanced search")
    expect(page).to have_field("last_name", with: "jud")
  end

  # The search button sits outside the results frame, so nothing replaces
  # it when the search comes back.
  it "leaves the search button ready for the next search" do
    visit patients_path

    within "#patients-panel-0" do
      click_button "Search"

      expect(page).to have_css(".btn-spinner.hidden", visible: :all)
      expect(page).to have_no_css("button[disabled]")
    end

    expect(page).to have_css("[role=alert]", text: "Enter something")
  end

  it "leaves no patient identifier in the url" do
    visit patients_path

    fill_in "urn", with: "0700003"
    click_button "Search"

    expect(page).to have_css("[role=alert]")
    expect(page.current_url).not_to include("0700003")
  end
end
