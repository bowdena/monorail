require "system_helper"

RSpec.describe "Home page", type: :system do
  it "names the service" do
    visit root_path

    expect(page).to have_css("h1", text: "Clinical Exchange")
  end

  # A stylesheet that built but reached the browser empty would still pass
  # a markup assertion, so read the value back out of the live document.
  it "resolves the design system's colour tokens" do
    visit root_path

    warning = evaluate_script(
      "getComputedStyle(document.documentElement)" \
      ".getPropertyValue('--warning')"
    )

    expect(warning.strip).not_to be_empty
  end

  it "styles components from the design system's stylesheet" do
    visit root_path

    border = evaluate_script(
      "getComputedStyle(document.querySelector('.card')).borderTopWidth"
    )

    expect(border).not_to eq("0px")
  end

  it "runs the design system's Stimulus controllers" do
    visit root_path

    expect(page).to have_no_css("dialog[open]", visible: :all)

    find("[aria-label='Notifications'][data-action]").click

    expect(page).to have_css("dialog[open]", visible: :all)
    expect(page).to have_text("No notifications yet")
  end
end
