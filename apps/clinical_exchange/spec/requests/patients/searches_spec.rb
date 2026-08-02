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

  # Conduit's name searches answer with a page, not an array.
  def ipm_page(records = [ ipm_patient ], page: 1, per_page: nil)
    Conduit::Page.of(records, page: page, per_page: per_page)
  end

  def ipm_patients(count)
    (1..count).map do |number|
      ipm_patient(urn: format("07%05d", number),
        first_name: format("Ann%03d", number))
    end
  end

  # Every name search now names the page it wants, so the criteria a
  # search reaches conduit with always carry these two.
  def searched_with(criteria)
    { first_name: nil, last_name: nil, date_of_birth: nil,
      page: 1, per_page: Patients::SearchesController::RESULTS_PER_PAGE }
      .merge(criteria)
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

  # A name search can match more than a screenful, so its pages have to
  # be reachable by a link. A urn search matches at most one patient and
  # stays a POST, keeping the identifier out of the url entirely.
  it "answers a name search inside the results frame" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      matching: ipm_page))

    get patients_search_path, params: { last_name: "Judd" }

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
      matching: ipm_page)
    stub_ipm(patients)

    get patients_search_path, params: {
      first_name: "Tori", last_name: "Judd", date_of_birth: "29/09/1957"
    }

    expect(patients).to have_received(:matching).with(
      searched_with(first_name: "Tori", last_name: "Judd",
        date_of_birth: Date.new(1957, 9, 29))
    )
    expect(Capybara.string(response.body))
      .to have_css("table.table td", text: "Tori Judd")
  end

  # 03/04 is a date either way round, so this is the example that pins
  # the order: 3 April, not 4 March.
  it "reads a date of birth day first" do
    patients = instance_double(Conduit::IPM::Repositories::Patients,
      matching: ipm_page)
    stub_ipm(patients)

    get patients_search_path, params: {
      last_name: "Judd", date_of_birth: "03/04/1957"
    }

    expect(patients).to have_received(:matching).with(
      searched_with(last_name: "Judd", date_of_birth: Date.new(1957, 4, 3))
    )
  end

  it "reads a date of birth written with dashes" do
    patients = instance_double(Conduit::IPM::Repositories::Patients,
      matching: ipm_page)
    stub_ipm(patients)

    get patients_search_path, params: {
      last_name: "Judd", date_of_birth: "3-4-1957"
    }

    expect(patients).to have_received(:matching).with(
      searched_with(last_name: "Judd", date_of_birth: Date.new(1957, 4, 3))
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
      matching: ipm_page)
    stub_ipm(patients)

    get patients_search_path, params: { last_name: "jud" }

    expect(patients).to have_received(:matching).with(
      searched_with(last_name: "jud")
    )
  end

  context "when no criterion is given" do
    it "asks for one and runs no query" do
      allow(Conduit).to receive(:ipm)

      get patients_search_path, params: { first_name: " " }

      expect(Conduit).not_to have_received(:ipm)
      expect(Capybara.string(response.body))
        .to have_css("[role=alert]", text: "Enter something to search for")
    end
  end

  context "when the date of birth is not a date" do
    it "says so rather than searching" do
      allow(Conduit).to receive(:ipm)

      get patients_search_path, params: {
        last_name: "Judd", date_of_birth: "31/02/1957"
      }

      expect(Conduit).not_to have_received(:ipm)
      expect(Capybara.string(response.body))
        .to have_css("[role=alert]", text: "Date of birth")
    end
  end

  describe "paging a long result set" do
    it "shows a page of results and the controls" do
      per_page = Patients::SearchesController::RESULTS_PER_PAGE
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        matching: ipm_page(ipm_patients(60), per_page: per_page)))

      get patients_search_path, params: { last_name: "jud" }

      page = Capybara.string(response.body)

      expect(page).to have_css("table.table tbody tr", count: per_page)
      expect(page).to have_css("nav[aria-label=Pagination]")
      expect(page).to have_link("2")
    end

    it "asks conduit for the page the url names" do
      patients = instance_double(Conduit::IPM::Repositories::Patients,
        matching: ipm_page(ipm_patients(60), page: 2,
          per_page: Patients::SearchesController::RESULTS_PER_PAGE))
      stub_ipm(patients)

      get patients_search_path, params: { last_name: "jud", page: "2" }

      expect(patients).to have_received(:matching).with(
        searched_with(last_name: "jud", page: 2)
      )
    end

    # A page link that dropped the criteria would search for everyone.
    it "carries the criteria into every page link" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        matching: ipm_page(ipm_patients(60),
          per_page: Patients::SearchesController::RESULTS_PER_PAGE)))

      get patients_search_path, params: { last_name: "jud" }

      link = Capybara.string(response.body).find_link("2")

      expect(link[:href]).to include("last_name=jud")
      expect(link[:href]).to include("page=2")
    end

    it "marks the page being read" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        matching: ipm_page(ipm_patients(60), page: 2,
          per_page: Patients::SearchesController::RESULTS_PER_PAGE)))

      get patients_search_path, params: { last_name: "jud", page: "2" }

      expect(Capybara.string(response.body))
        .to have_css("nav[aria-label=Pagination] [aria-current=page]",
          text: "2")
    end

    it "offers previous and next where they exist" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        matching: ipm_page(ipm_patients(60), page: 2,
          per_page: Patients::SearchesController::RESULTS_PER_PAGE)))

      get patients_search_path, params: { last_name: "jud", page: "2" }

      page = Capybara.string(response.body)

      expect(page).to have_link(nil, href: /page=1/)
      expect(page).to have_link(nil, href: /page=3/)
    end

    # Every page of a thousand would be unreadable, so the window shows
    # the ends, the current page and its neighbours, and elides the rest.
    it "elides the middle of a long run of pages" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        matching: ipm_page(ipm_patients(500), page: 10, per_page: 5)))

      get patients_search_path, params: { last_name: "jud", page: "10" }

      page = Capybara.string(response.body)

      expect(page).to have_css("nav[aria-label=Pagination] li", maximum: 9)
      expect(page).to have_text("More pages")
      expect(page).to have_link("1")
      expect(page).to have_link("100")
    end

    context "when everything fits on one page" do
      it "shows no controls" do
        stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
          matching: ipm_page(ipm_patients(3),
            per_page: Patients::SearchesController::RESULTS_PER_PAGE)))

        get patients_search_path, params: { last_name: "jud" }

        page = Capybara.string(response.body)

        expect(page).to have_css("table.table")
        expect(page).to have_no_css("nav[aria-label=Pagination]")
      end
    end

    context "when a urn was searched for" do
      it "shows no controls" do
        stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
          by_urn: ipm_patient))

        post patients_search_path, params: { urn: "0700003" }

        expect(Capybara.string(response.body))
          .to have_no_css("nav[aria-label=Pagination]")
      end
    end

    context "when iPM is unreachable" do
      it "pages the locally kept records too" do
        per_page = Patients::SearchesController::RESULTS_PER_PAGE
        (per_page + 5).times do |number|
          create(:patient, last_name: "Judd",
            first_name: format("Ann%02d", number))
        end
        patients = instance_double(Conduit::IPM::Repositories::Patients)
        allow(patients).to receive(:matching).and_raise(
          Conduit::Error::Timeout.new("slow", source: :ipm)
        )
        stub_ipm(patients)

        get patients_search_path, params: { last_name: "jud" }

        page = Capybara.string(response.body)

        expect(page).to have_css("table.table tbody tr", count: per_page)
        expect(page).to have_css("nav[aria-label=Pagination]")
      end
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
      matching: ipm_page))

    get patients_search_path, params: {
      first_name: "Tori", last_name: "Judd", date_of_birth: "29/09/1957"
    }

    logged = request.filtered_parameters

    expect(logged["first_name"]).to eq("[FILTERED]")
    expect(logged["date_of_birth"]).to eq("[FILTERED]")
  end

  # A name search carries its criteria in the query string now, and the
  # request line is what Rails logs. filtered_path is that line.
  it "keeps them out of the logged url too" do
    stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
      matching: ipm_page))

    get patients_search_path, params: {
      first_name: "Tori", last_name: "Judd", date_of_birth: "29/09/1957"
    }

    expect(request.filtered_path).not_to include("Tori")
    expect(request.filtered_path).not_to include("1957")
    expect(request.filtered_path).to include("Judd")
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
