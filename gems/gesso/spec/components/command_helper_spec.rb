require "rails_helper"

# Unit spec for the command view helper. render_command renders the
# gesso/components/command partial (a structural pass-through); here we call it
# directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::CommandHelper, type: :helper do
  it "renders a search input in the header" do
    html = helper.render_command(groups: [])
    expect(Capybara.string(html)).to have_css("div.command > header input")
  end

  it "renders group headings and their items" do
    html = helper.render_command(groups: [
      { label: "Navigation",
        items: [ { label: "Dashboard", href: "/dashboard", icon: "users" } ] }
    ])
    page = Capybara.string(html)
    expect(page).to have_css("[role='heading']", text: "Navigation")
    expect(page).to have_css("[role='group'] [role='menuitem']", text: "Dashboard")
  end

  it "renders a menu item without an icon" do
    html = helper.render_command(groups: [
      { label: "Actions", items: [ { label: "Reports", href: "/reports" } ] }
    ])
    expect(Capybara.string(html)).to have_css("a[role='menuitem']", text: "Reports")
  end

  it "sets data-empty for a custom empty state" do
    html = helper.render_command(empty: "Nothing here yet.", groups: [])
    expect(Capybara.string(html))
      .to have_css("[role='menu'][data-empty='Nothing here yet.']")
  end

  it "omits data-empty when no empty text is given" do
    html = helper.render_command(groups: [])
    expect(Capybara.string(html)).to have_no_css("[role='menu'][data-empty]")
  end

  it "uses the given placeholder" do
    html = helper.render_command(placeholder: "Type a command…", groups: [])
    expect(Capybara.string(html))
      .to have_css("header input[placeholder='Type a command…']")
  end
end
