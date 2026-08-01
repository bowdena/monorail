require "rails_helper"

# The combobox is wired by basecoat-css's bundled select.js. Regression:
# the turbo:load handler used to run initAll over components the bundled
# DOMContentLoaded init had already wired. The duplicate init crashed on
# the select's already-defined value property and left the trigger with
# paired open/close listeners, so clicking the combobox did nothing.
RSpec.describe "Combobox", type: :system do
  it "opens the listbox and selects an option" do
    visit "/lookbook/preview/combobox/default"

    find("button[aria-haspopup='listbox']").click

    expect(page).to have_css("[role='option']", text: "Django")

    find("[role='option']", text: "Django").click

    expect(page).to have_button("Django")
    expect(find("input[name='framework']", visible: :all).value)
      .to eq("django")
  end
end
