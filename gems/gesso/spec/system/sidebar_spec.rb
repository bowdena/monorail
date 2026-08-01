require "rails_helper"

RSpec.describe "Sidebar", type: :system do
  before do
    visit "/lookbook/preview/sidebar/default"
    execute_script("localStorage.removeItem('sidebar-collapsed')")
  end

  it "collapses and expands" do
    expect(page).not_to have_css(
      "[data-controller='sidebar'][data-collapsed='true']",
      visible: :all
    )

    find("[data-action='click->sidebar#toggle']").click

    expect(page).to have_css(
      "[data-controller='sidebar'][data-collapsed='true']",
      visible: :all
    )

    find("[data-action='click->sidebar#toggle']").click

    expect(page).not_to have_css(
      "[data-controller='sidebar'][data-collapsed='true']",
      visible: :all
    )
  end

  it "hides nav item labels when collapsed, leaving the icons" do
    within("#main-sidebar") do
      expect(page).to have_text("Patients")
    end

    find("[data-action='click->sidebar#toggle']").click

    within("#main-sidebar") do
      expect(page).to have_no_text("Patients")
      expect(page).to have_css("a[href='/patients'] svg", visible: :all)
    end
  end

  it "persists collapsed state across page loads" do
    find("[data-action='click->sidebar#toggle']").click

    visit "/lookbook/preview/sidebar/default"

    expect(page).to have_css(
      "[data-controller='sidebar'][data-collapsed='true']",
      visible: :all
    )
  end

  context "active highlight across Turbo navigation" do
    it "moves aria-current to the page navigated to without a refresh" do
      visit "/"

      within("#main-sidebar") do
        expect(page).to have_css('a[aria-current="page"]', text: "Dashboard")

        click_link "Patients"

        expect(page).to have_css('a[aria-current="page"]', text: "Patients")
        expect(page).to have_no_css('a[aria-current="page"]', text: "Dashboard")
      end
    end
  end
end
