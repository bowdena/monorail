require "rails_helper"

RSpec.describe "Theme toggle", type: :system do
  it "persists the dark theme preference across page loads" do
    visit "/lookbook/preview/theme_toggle/default"
    # Clear any prior state so the test runs from a known starting point
    execute_script(
      "localStorage.removeItem('theme-preference');" \
      "document.documentElement.classList.remove('dark')"
    )

    expect(page).not_to have_css("html.dark", visible: :all)

    # Cycle: system → light (click 1), light → dark (click 2)
    find("[data-controller='theme']").click
    find("[data-controller='theme']").click

    expect(page).to have_css("html.dark", visible: :all)

    visit "/lookbook/preview/theme_toggle/default"

    expect(page).to have_css("html.dark", visible: :all)
  end
end
