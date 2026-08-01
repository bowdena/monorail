require "rails_helper"

# Rendered through the Lookbook preview route; the body is parsed with
# Capybara.string so DOM matchers can query it.
RSpec.describe "Patient info header", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/patient_search/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders stub patient data" do
    page = render_preview("default")
    expect(page).to have_text("Jane Smith")
    expect(page).to have_text("1234567")
  end
end
