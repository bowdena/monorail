require "system_helper"

# Nothing serves iPM in the test environment, so a search here always
# takes the fallback path — which makes this the end-to-end cover for a
# clinician searching while the replica is unreachable.
RSpec.describe "Patient lookup", type: :system do
  # The server runs in this process, so conduit can be stubbed for a
  # browser journey the same way it is in a request spec.
  def stub_ipm(patients)
    allow(Conduit).to receive(:ipm)
      .and_return(instance_double(Conduit::IPM::Repos, patients: patients))
  end

  def ipm_patient(urn: "0700003", first_name: "Tori", last_name: "Judd")
    Conduit::IPM::Patient.new(
      urn: urn, first_name: first_name, last_name: last_name,
      date_of_birth: Date.new(1957, 9, 29), gender: "Female",
      atsi_status: nil, merged_from: nil
    )
  end

  it "takes a clinician from the sidebar to a patient" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    visit root_path
    click_link "Patients"

    within "#patients-panel-0" do
      fill_in "urn", with: "700003"
      click_button "Search"
    end

    expect(page).to have_css("table.table td", text: "Tori Judd")
    expect(page).to have_no_css("[role=alert]")

    click_button "Select"

    expect(page).to have_text("Tori Judd")
    expect(page).to have_text("UR: 0700003")
    expect(page).to have_text("29/09/1957")
    expect(Patient.sole.urn).to eq("0700003")
  end

  it "still finds a kept patient once iPM goes away" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    visit patients_path

    within "#patients-panel-0" do
      fill_in "urn", with: "0700003"
      click_button "Search"
    end

    click_button "Select"

    expect(page).to have_text("Tori Judd")

    unreachable = instance_double(Conduit::IPM::Repositories::Patients)
    allow(unreachable).to receive(:by_urn).and_raise(
      Conduit::Error::ConnectionFailed.new("down", source: :ipm)
    )
    stub_ipm(unreachable)

    click_link "Back to search"

    within "#patients-panel-0" do
      fill_in "urn", with: "0700003"
      click_button "Search"
    end

    expect(page).to have_css("[role=alert]", text: "iPM is unavailable")
    expect(page).to have_css("table.table td", text: "Tori Judd")
  end

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

  it "opens the patient a clinician selects" do
    create(:patient, urn: "0700003", first_name: "Tori", last_name: "Judd")

    visit patients_path

    within "#patients-panel-0" do
      fill_in "urn", with: "0700003"
      click_button "Search"
    end

    click_button "Select"

    expect(page).to have_text("Tori Judd")
    expect(page).to have_text("UR: 0700003")
    expect(page.current_path).to eq(patient_path(Patient.sole))
    expect(page.current_url).not_to include("0700003")
  end

  it "leaves no patient identifier in the url" do
    visit patients_path

    fill_in "urn", with: "0700003"
    click_button "Search"

    expect(page).to have_css("[role=alert]")
    expect(page.current_url).not_to include("0700003")
  end
end
