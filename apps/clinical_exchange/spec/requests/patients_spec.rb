require "rails_helper"

# The body is parsed with Capybara.string so DOM matchers can query it,
# matching how the gesso engine specs its own components.
RSpec.describe "Patients", type: :request do
  it "offers a urn search" do
    get patients_path

    page = Capybara.string(response.body)

    expect(page).to have_field("urn")
    expect(page).to have_button("Search")
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
