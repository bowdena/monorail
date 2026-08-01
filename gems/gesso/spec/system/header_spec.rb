require "rails_helper"

RSpec.describe "Header", type: :system do
  it "opens and closes the notification drawer" do
    visit "/lookbook/preview/header/default"

    expect(page).not_to have_css("dialog[open]", visible: :all)

    find("[aria-label='Notifications'][data-action]").click

    expect(page).to have_css("dialog[open]", visible: :all)
    expect(page).to have_text("Notifications")

    find("[aria-label='Close notifications']").click

    expect(page).not_to have_css("dialog[open]", visible: :all)
  end

  it "reopens the user menu after Turbo navigation" do
    visit "/"

    find('header button[aria-haspopup="menu"]').click
    expect(page).to have_css(
      'header button[aria-haspopup="menu"][aria-expanded="true"]')

    # close it, then Turbo-navigate to another page
    find('header button[aria-haspopup="menu"]').click
    click_link "Patients"
    expect(page).to have_css("h1", text: "Patients")

    # the menu must still open (a duplicated toggle listener would cancel
    # the click out, leaving it closed)
    find('header button[aria-haspopup="menu"]').click
    expect(page).to have_css(
      'header button[aria-haspopup="menu"][aria-expanded="true"]')
  end

  it "defines a foreground colour for the unread badge" do
    # The badge is bg-destructive with text in --destructive-foreground.
    # basecoat omits that token; without theme.css defining it the text
    # falls back to inherited dark, giving dark-red-on-dark in light mode.
    visit "/lookbook/preview/header/default"

    foreground = evaluate_script(
      "getComputedStyle(document.documentElement)" \
      ".getPropertyValue('--destructive-foreground').trim()"
    )
    expect(foreground).not_to be_empty
  end

  it "closes the notification drawer on a backdrop click" do
    visit "/lookbook/preview/header/default"

    find("[aria-label='Notifications'][data-action]").click

    expect(page).to have_css("dialog[open]", visible: :all)

    # The drawer panel fills its own <dialog> box, so the backdrop is the
    # dialog element itself. A real backdrop click lands on the dialog with
    # event.target === the panel; dispatch that click to exercise
    # drawer#backdropClick the way the browser would.
    execute_script(
      "document.querySelector('dialog.notification-drawer')" \
      ".dispatchEvent(new MouseEvent('click', { bubbles: true }))"
    )

    expect(page).not_to have_css("dialog[open]", visible: :all)
  end
end
