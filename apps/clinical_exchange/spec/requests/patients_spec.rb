require "rails_helper"

# The body is parsed with Capybara.string so DOM matchers can query it,
# matching how the gesso engine specs its own components.
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

  describe "selecting a patient" do
    it "keeps the patient and opens their page" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient))

      expect { post patients_path, params: { urn: "0700003" } }
        .to change(Patient, :count).by(1)

      patient = Patient.sole

      expect(response).to redirect_to(patient_path(patient))
      expect(patient.last_name).to eq("Judd")
    end

    it "addresses the patient by uuid, never by urn" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient))

      post patients_path, params: { urn: "0700003" }

      expect(response.location).to include(Patient.sole.id)
      expect(response.location).not_to include("0700003")
    end

    it "keeps one record when the same patient is selected twice" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient))

      post patients_path, params: { urn: "0700003" }

      expect { post patients_path, params: { urn: "0700003" } }
        .not_to change(Patient, :count)
    end

    it "keeps a patient already held when iPM is unreachable" do
      create(:patient, urn: "0700003", last_name: "Judd")
      patients = instance_double(Conduit::IPM::Repositories::Patients)
      allow(patients).to receive(:by_urn).and_raise(
        Conduit::Error::ConnectionFailed.new("down", source: :ipm)
      )
      stub_ipm(patients)

      post patients_path, params: { urn: "0700003" }

      expect(response).to redirect_to(patient_path(Patient.sole))
    end

    it "refuses a urn no patient has" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: nil))

      post patients_path, params: { urn: "0700003" }

      expect(response).to have_http_status(:not_found)
      expect(Patient.count).to be_zero
    end
  end

  describe "a patient's page" do
    it "confirms who the patient is" do
      patient = create(:patient, urn: "0700003", first_name: "Tori",
        last_name: "Judd", date_of_birth: Date.new(1957, 9, 29),
        gender: "Female")

      get patient_path(patient)

      page = Capybara.string(response.body)

      expect(page).to have_text("Tori Judd")
      expect(page).to have_text("UR: 0700003")
      expect(page).to have_text("29/09/1957")
    end

    it "has nothing to show for a patient never kept" do
      get patient_path(SecureRandom.uuid)

      expect(response).to have_http_status(:not_found)
    end
  end

  it "offers a urn search" do
    get patients_path

    page = Capybara.string(response.body)

    expect(page).to have_field("urn")
    expect(page).to have_button("Search")
  end

  it "offers an advanced search beside the urn search" do
    get patients_path

    page = Capybara.string(response.body)

    expect(page).to have_css("[role=tab]", text: "URN")
    expect(page).to have_css("[role=tab]", text: "Advanced")
    expect(page).to have_field("first_name", visible: :all)
    expect(page).to have_field("last_name", visible: :all)
    expect(page).to have_field("date_of_birth", visible: :all)
  end

  it "posts the search rather than putting criteria in the url" do
    get patients_path

    expect(Capybara.string(response.body))
      .to have_css("form[action='#{patients_search_path}'][method=post]")
  end

  # A searchable GET is an enumeration surface: the criteria land in the
  # address bar, the history and the access log, and another origin can
  # trigger the query in a clinician's session.
  it "runs no search from the query string" do
    allow(Conduit).to receive(:ipm)

    get patients_path(urn: "0700003")

    expect(Conduit).not_to have_received(:ipm)
    expect(Capybara.string(response.body)).to have_no_css("table.table")
  end
end
