require "rails_helper"

# The combobox is wired by basecoat-css's bundled combobox.js. Regression:
# the turbo:load handler used to run initAll over components the bundled
# DOMContentLoaded init had already wired. The duplicate init crashed on
# the already-defined value property and left the control with paired
# open/close listeners, so clicking the combobox did nothing.
RSpec.describe "Combobox", type: :system do
  it "opens the listbox and selects an option" do
    visit "/lookbook/preview/combobox/default"

    find("input[role='combobox']").click

    expect(page).to have_css("[role='option']", text: "Django")

    find("[role='option']", text: "Django").click

    expect(find("input[role='combobox']").value).to eq("Django")
    expect(find("input[name='framework']", visible: :all).value).to eq("django")
  end

  # basecoat leaves whatever was typed in the input when focus moves away,
  # so a half-typed or unmatched entry sits on screen while the submitted
  # value is something else entirely.
  it "restores the selected label when abandoned mid-search" do
    visit "/lookbook/preview/combobox/default"

    find("input[role='combobox']").send_keys([ :control, "a" ], "djan")
    find("body").click

    expect(find("input[role='combobox']").value).to eq("Ruby on Rails")
    expect(find("input[name='framework']", visible: :all).value).to eq("rails")
  end

  it "restores the most recent selection, not the original one" do
    visit "/lookbook/preview/combobox/default"

    find("input[role='combobox']").click
    find("[role='option']", text: "Laravel").click
    find("input[role='combobox']").send_keys([ :control, "a" ], "spr")
    find("body").click

    expect(find("input[role='combobox']").value).to eq("Laravel")
    expect(find("input[name='framework']", visible: :all).value).to eq("laravel")
  end

  it "clears an abandoned search when nothing is selected" do
    visit "/lookbook/preview/combobox/no_selection"

    find("input[role='combobox']").send_keys("nonsense")
    find("body").click

    expect(find("input[role='combobox']").value).to eq("")
    expect(find("input[name='framework']", visible: :all).value).to eq("")
  end

  # Regression: basecoat 1.0 moved filtering out of select.js into its own
  # combobox component. The old markup still opened and still selected on
  # click, so only typing catches a combobox wired to the wrong component.
  it "filters the options as you type" do
    visit "/lookbook/preview/combobox/default"

    find("input[role='combobox']").send_keys([ :control, "a" ], "djan")

    expect(page).to have_css("[role='option']", text: "Django", visible: true)
    expect(page).to have_no_css("[role='option']", text: "Laravel", visible: true)
  end
end
