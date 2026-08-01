require "rails_helper"

# The body is parsed with Capybara.string so DOM matchers can query it,
# matching how the gesso engine specs its own components.
RSpec.describe "App chrome", type: :request do
  it "renders the sidebar on every page" do
    get root_path

    page = Capybara.string(response.body)

    expect(page).to have_css("aside#main-sidebar", text: "Clinical Exchange")
    expect(page).to have_link("Dashboard", href: root_path)
  end

  it "marks the current section in the sidebar" do
    get root_path

    expect(Capybara.string(response.body))
      .to have_css("aside#main-sidebar a[aria-current=page]", text: "Dashboard")
  end

  it "renders one header, titled for the page" do
    get root_path

    page = Capybara.string(response.body)

    expect(page).to have_css("header#main-header", count: 1)
    expect(page).to have_css("header#main-header h1", text: "Clinical Exchange")
  end
end
