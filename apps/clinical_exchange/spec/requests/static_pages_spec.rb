require "rails_helper"

# The body is parsed with Capybara.string so DOM matchers can query it,
# matching how the gesso engine specs its own components.
RSpec.describe "Static pages", type: :request do
  def render_home
    get root_path
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "serves the home page at the root path" do
    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "names the service in the page heading" do
    expect(render_home)
      .to have_css("header#main-header h1", text: "Clinical Exchange")
  end

  it "builds the page from design system components" do
    expect(render_home).to have_css("div.card section")
  end

  it "offers no search, because there is nothing yet to search" do
    expect(render_home).to have_no_css("header#main-header input[type=search]")
  end
end
