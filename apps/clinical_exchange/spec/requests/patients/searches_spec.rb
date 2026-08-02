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
    expect(page).to have_css("table.table td", text: "29/09/1957")
    expect(page).to have_css("table.table td", text: "Female")
  end

  it "answers inside the results frame" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    post patients_search_path, params: { urn: "0700003" }

    expect(Capybara.string(response.body))
      .to have_css("turbo-frame#patient_results table.table", visible: :all)
  end

  it "reports a urn no patient has" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: nil))

    post patients_search_path, params: { urn: "0700003" }

    page = Capybara.string(response.body)

    expect(page).to have_css("[role=alert]", text: "No patient found")
    expect(page).to have_no_css("table.table")
  end

  it "lists patients matching name and date of birth" do
    patients = instance_double(Conduit::IPM::Repositories::Patients,
      matching: [ ipm_patient ])
    stub_ipm(patients)

    post patients_search_path, params: {
      first_name: "Tori", last_name: "Judd", date_of_birth: "29/09/1957"
    }

    expect(patients).to have_received(:matching).with(
      first_name: "Tori", last_name: "Judd",
      date_of_birth: Date.new(1957, 9, 29)
    )
    expect(Capybara.string(response.body))
      .to have_css("table.table td", text: "Tori Judd")
  end

  # 03/04 is a date either way round, so this is the example that pins
  # the order: 3 April, not 4 March.
  it "reads a date of birth day first" do
    patients = instance_double(Conduit::IPM::Repositories::Patients,
      matching: [ ipm_patient ])
    stub_ipm(patients)

    post patients_search_path, params: {
      last_name: "Judd", date_of_birth: "03/04/1957"
    }

    expect(patients).to have_received(:matching).with(
      first_name: nil, last_name: "Judd",
      date_of_birth: Date.new(1957, 4, 3)
    )
  end

  it "reads a date of birth written with dashes" do
    patients = instance_double(Conduit::IPM::Repositories::Patients,
      matching: [ ipm_patient ])
    stub_ipm(patients)

    post patients_search_path, params: {
      last_name: "Judd", date_of_birth: "3-4-1957"
    }

    expect(patients).to have_received(:matching).with(
      first_name: nil, last_name: "Judd",
      date_of_birth: Date.new(1957, 4, 3)
    )
  end

  # A browser posts the forgery token with every form. Permitting the
  # whole params hash flags it as unpermitted on every search.
  it "takes no notice of the parameters a browser adds" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))
    ActionController::Parameters.action_on_unpermitted_parameters = :raise

    expect {
      post patients_search_path,
        params: { urn: "0700003", authenticity_token: "a-token" }
    }.not_to raise_error
  ensure
    ActionController::Parameters.action_on_unpermitted_parameters = false
  end

  it "searches on a single criterion" do
    patients = instance_double(Conduit::IPM::Repositories::Patients,
      matching: [ ipm_patient ])
    stub_ipm(patients)

    post patients_search_path, params: { last_name: "jud" }

    expect(patients).to have_received(:matching).with(
      first_name: nil, last_name: "jud", date_of_birth: nil
    )
  end

  context "when no criterion is given" do
    it "asks for one and runs no query" do
      allow(Conduit).to receive(:ipm)

      post patients_search_path, params: { first_name: " " }

      expect(Conduit).not_to have_received(:ipm)
      expect(Capybara.string(response.body))
        .to have_css("[role=alert]", text: "Enter something to search for")
    end
  end

  context "when the date of birth is not a date" do
    it "says so rather than searching" do
      allow(Conduit).to receive(:ipm)

      post patients_search_path, params: {
        last_name: "Judd", date_of_birth: "31/02/1957"
      }

      expect(Conduit).not_to have_received(:ipm)
      expect(Capybara.string(response.body))
        .to have_css("[role=alert]", text: "Date of birth")
    end
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

  # filtered_parameters is what Rails writes to the log for a request.
  it "keeps the name and date of birth out of the log" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      matching: [ ipm_patient ]))

    post patients_search_path, params: {
      first_name: "Tori", last_name: "Judd", date_of_birth: "29/09/1957"
    }

    logged = request.filtered_parameters

    expect(logged["first_name"]).to eq("[FILTERED]")
    expect(logged["date_of_birth"]).to eq("[FILTERED]")
  end

  it "leaves the urn readable in the log" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      by_urn: ipm_patient))

    post patients_search_path, params: { urn: "0700003" }

    expect(request.filtered_parameters["urn"]).to eq("0700003")
  end

  # The counter lives in Rails.cache, which spec/support/rate_limits.rb
  # clears before every example.
  context "when searches come too fast" do
    it "refuses the ones beyond the cap" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient))

      (Patients::SearchesController::SEARCHES_PER_MINUTE + 1).times do
        post patients_search_path, params: { urn: "0700003" }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(Capybara.string(response.body))
        .to have_css("[role=alert]", text: "Too many searches")
    end

    it "allows searching up to the cap" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient))

      Patients::SearchesController::SEARCHES_PER_MINUTE.times do
        post patients_search_path, params: { urn: "0700003" }
      end

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_css("table.table")
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
