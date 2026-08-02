require "rails_helper"

# The body is parsed with Capybara.string so DOM matchers can query it,
# matching how the gesso engine specs its own components. Conduit is
# stubbed at its public boundary, so the suite never reaches MSSQL.
RSpec.describe "Patient searches", type: :request do
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

  it "lists the patient matching a urn" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    post patients_search_path, params: { urn: "0700003" }

    page = Capybara.string(response.body)

    expect(page).to have_css("table.table td", text: "Tori Judd")
    expect(page).to have_css("table.table td", text: "0700003")
    expect(page).to have_css("table.table td", text: "29 Sep 1957")
    expect(page).to have_css("table.table td", text: "Female")
  end

  it "answers inside the search frame" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    post patients_search_path, params: { urn: "0700003" }

    expect(Capybara.string(response.body))
      .to have_css("turbo-frame#patient_search table.table", visible: :all)
  end

  it "reports a urn no patient has" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: nil))

    post patients_search_path, params: { urn: "0700003" }

    page = Capybara.string(response.body)

    expect(page).to have_css("[role=alert]", text: "No patient found")
    expect(page).to have_no_css("table.table")
  end

  it "keeps the urn out of the response url" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    post patients_search_path, params: { urn: "0700003" }

    expect(response).to have_http_status(:ok)
    expect(request.fullpath).not_to include("0700003")
  end

  it "raises no alert when iPM answered" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    post patients_search_path, params: { urn: "0700003" }

    expect(Capybara.string(response.body))
      .to have_no_css("[role=alert]")
  end

  context "when iPM is unreachable" do
    it "says the results came from saved records" do
      create(:patient, urn: "0700003", last_name: "Judd")
      patients = instance_double(Conduit::IPM::Repositories::Patients)
      allow(patients).to receive(:by_urn).and_raise(
        Conduit::Error::ConnectionFailed.new("down", source: :ipm)
      )
      stub_ipm(patients)

      post patients_search_path, params: { urn: "0700003" }

      page = Capybara.string(response.body)

      expect(page).to have_css("[role=alert][data-variant=warning]",
        text: "iPM is unavailable")
      expect(page).to have_css("table.table td", text: "Judd")
    end

    # "No patient found" would say iPM denied the patient exists, when
    # the truth is that nobody could ask it.
    it "does not claim the patient does not exist" do
      patients = instance_double(Conduit::IPM::Repositories::Patients)
      allow(patients).to receive(:by_urn).and_raise(
        Conduit::Error::Timeout.new("slow", source: :ipm)
      )
      stub_ipm(patients)

      post patients_search_path, params: { urn: "0700003" }

      page = Capybara.string(response.body)

      expect(page).to have_css("[role=alert][data-variant=warning]",
        text: "iPM is unavailable")
      expect(page).to have_text("No saved patient")
      expect(page).to have_no_text("No patient found")
    end
  end

  context "when the search fails outright" do
    it "reports the failure instead of results" do
      create(:patient, urn: "0700003")
      patients = instance_double(Conduit::IPM::Repositories::Patients)
      allow(patients).to receive(:by_urn).and_raise(
        Conduit::Error::PermissionDenied.new("no grant", source: :ipm)
      )
      stub_ipm(patients)

      post patients_search_path, params: { urn: "0700003" }

      page = Capybara.string(response.body)

      expect(page).to have_css("[role=alert][data-variant=critical]",
        text: "Search unavailable")
      expect(page).to have_no_css("table.table")
    end
  end
end
