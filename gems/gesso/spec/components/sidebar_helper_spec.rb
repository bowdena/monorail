require "rails_helper"

# Unit spec for the sidebar view helper. render_sidebar derives the
# active section from the request path and renders the components/sidebar
# partial; here we call it directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::SidebarHelper, type: :helper do
  it "renders the app name and a nav item per entry" do
    html = helper.render_sidebar(
      app_name: "NHS App",
      nav_items: [
        { label: "Dashboard", path: "/", icon: "layout-dashboard" },
        { label: "Patients", path: "/patients", icon: "users" }
      ]
    )
    page = Capybara.string(html)
    expect(page).to have_css("aside#main-sidebar.sidebar")
    expect(page).to have_text("NHS App")
    expect(page).to have_css("nav ul li", count: 2)
  end

  it "links each nav item to its path" do
    html = helper.render_sidebar(
      nav_items: [ { label: "Patients", path: "/patients", icon: "users" } ])
    expect(Capybara.string(html))
      .to have_css('nav a[href="/patients"]', text: "Patients")
  end

  it "renders the theme toggle in the footer" do
    html = helper.render_sidebar(nav_items: [])
    expect(Capybara.string(html))
      .to have_css('footer button[data-controller="theme"]')
  end

  it "marks the section matching the request path with aria-current" do
    allow(helper).to receive(:request)
      .and_return(instance_double(ActionDispatch::Request, path: "/patients"))
    html = helper.render_sidebar(
      nav_items: [
        { label: "Patients", path: "/patients", icon: "users" },
        { label: "Settings", path: "/settings", icon: "settings" }
      ]
    )
    page = Capybara.string(html)
    expect(page).to have_css('a[href="/patients"][aria-current="page"]')
    expect(page).to have_no_css('a[href="/settings"][aria-current]')
  end

  it "matches the root section only on an exact path" do
    allow(helper).to receive(:request)
      .and_return(instance_double(ActionDispatch::Request, path: "/patients"))
    html = helper.render_sidebar(
      nav_items: [ { label: "Dashboard", path: "/", icon: "layout-dashboard" } ])
    expect(Capybara.string(html)).to have_no_css('a[href="/"][aria-current]')
  end
end
