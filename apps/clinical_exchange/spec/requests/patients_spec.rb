require "rails_helper"

# The body is parsed with Capybara.string so DOM matchers can query it,
# matching how the gesso engine specs its own components. Conduit is
# stubbed at its public boundary, so the suite never reaches MSSQL.
RSpec.describe "Patients", type: :request do
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

  it "offers a urn search" do
    get patients_path

    page = Capybara.string(response.body)

    expect(page).to have_field("urn")
    expect(page).to have_button("Search")
  end

  it "lists the patient matching a urn" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    get patients_path(urn: "0700003")

    page = Capybara.string(response.body)

    expect(page).to have_css("table.table td", text: "Tori Judd")
    expect(page).to have_css("table.table td", text: "0700003")
    expect(page).to have_css("table.table td", text: "29 Sep 1957")
    expect(page).to have_css("table.table td", text: "Female")
  end

  it "reports a urn no patient has" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: nil))

    get patients_path(urn: "0700003")

    page = Capybara.string(response.body)

    expect(page).to have_css("[role=alert]", text: "No patient found")
    expect(page).to have_no_css("table.table")
  end
end
