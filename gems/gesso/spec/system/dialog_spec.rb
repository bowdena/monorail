require "rails_helper"

RSpec.describe "Dialog", type: :system do
  it "opens from the trigger and closes via the close button" do
    visit "/lookbook/preview/dialog/default"

    expect(page).not_to have_css("dialog[open]", visible: :all)

    click_button "Open dialog"

    expect(page).to have_css("dialog[open]", visible: :all)
    expect(page).to have_text("Session expired")

    find("[aria-label='Close']").click

    expect(page).not_to have_css("dialog[open]", visible: :all)
  end

  it "closes on a backdrop click" do
    visit "/lookbook/preview/dialog/default"

    click_button "Open dialog"

    expect(page).to have_css("dialog[open]", visible: :all)

    # The content box is centred inside the dialog, so the backdrop is the
    # dialog element itself. A real backdrop click lands on the dialog with
    # event.target === the panel; dispatch that click to exercise
    # drawer#backdropClick the way the browser would.
    execute_script(
      "document.querySelector('dialog.dialog')" \
      ".dispatchEvent(new MouseEvent('click', { bubbles: true }))"
    )

    expect(page).not_to have_css("dialog[open]", visible: :all)
  end
end
