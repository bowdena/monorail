require "rails_helper"

# Tab switching is handled by basecoat-css's bundled JS (no Stimulus
# controller). This drives the Lookbook preview page, which loads that JS,
# to confirm switching works end to end.
RSpec.describe "Tabs", type: :system do
  it "switches the visible panel when a tab is clicked" do
    visit "/lookbook/preview/tabs/default"

    expect(page).to have_css("#demo-panel-0:not([hidden])", text: "Your profile details.")
    expect(page).to have_css("#demo-panel-1[hidden]", visible: :all)

    click_button "Preferences"

    expect(page).to have_css("#demo-panel-1:not([hidden])", text: "Your preferences.")
    expect(page).to have_css("#demo-panel-0[hidden]", visible: :all)
  end
end
