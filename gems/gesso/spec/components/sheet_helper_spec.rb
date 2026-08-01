require "rails_helper"

# Unit spec for the sheet view helper. render_sheet validates the side
# and renders the gesso/components/sheet partial with the block as the panel
# body; here we call it directly and assert on the HTML it returns. The
# dialog is closed in the markup, so matchers use visible: :all.
RSpec.describe Gesso::Components::SheetHelper, type: :helper do
  it "renders a native dialog shell with the drawer panel wiring" do
    html = helper.render_sheet(id: "demo", aria_label: "Demo") { "Body" }
    page = Capybara.string(html)
    expect(page).to have_css(
      "dialog#demo.sheet[data-drawer-target='panel']", visible: :all
    )
    expect(page).to have_css(
      "dialog[data-action='click->drawer#backdropClick']", visible: :all
    )
  end

  it "labels the dialog from aria_label" do
    html = helper.render_sheet(id: "demo", aria_label: "Notifications") { "x" }
    expect(Capybara.string(html))
      .to have_css("dialog[aria-label='Notifications']", visible: :all)
  end

  it "renders the block as the panel body" do
    html = helper.render_sheet(id: "demo", aria_label: "Demo") { "Panel body." }
    expect(Capybara.string(html)).to have_text("Panel body.")
  end

  it "places the sheet on the right by default" do
    html = helper.render_sheet(id: "demo", aria_label: "Demo") { "x" }
    page = Capybara.string(html)
    expect(page).to have_css("dialog.sheet-right", visible: :all)
    expect(page).to have_no_css("dialog.sheet-left", visible: :all)
  end

  it "places the sheet on the left when side is left" do
    html = helper.render_sheet(id: "demo", aria_label: "Demo", side: "left") { "x" }
    expect(Capybara.string(html)).to have_css("dialog.sheet-left", visible: :all)
  end

  it "appends caller-supplied classes" do
    html = helper.render_sheet(id: "demo", aria_label: "Demo",
                               classes: "notification-drawer") { "x" }
    expect(Capybara.string(html))
      .to have_css("dialog.sheet.notification-drawer", visible: :all)
  end

  it "raises ArgumentError for an unknown side" do
    expect { helper.render_sheet(id: "demo", aria_label: "Demo", side: "top") { "x" } }
      .to raise_error(ArgumentError, /side/)
  end
end
