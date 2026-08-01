require "rails_helper"

# Unit spec for the tabs view helper. render_tabs renders the
# gesso/components/tabs partial (a structural pass-through); here we call it
# directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::TabsHelper, type: :helper do
  it "renders the aria tab markup basecoat wires up" do
    html = helper.render_tabs(id: "demo", tabs: [
      { label: "Profile", content: "Your profile details." },
      { label: "Preferences", content: "Your preferences." }
    ])
    page = Capybara.string(html)
    expect(page).to have_css('.tabs [role="tablist"]')
    expect(page).to have_css('[role="tab"][aria-controls="demo-panel-0"]')
  end

  it "selects the first tab and hides the rest initially" do
    html = helper.render_tabs(id: "demo", tabs: [
      { label: "Profile", content: "Your profile details." },
      { label: "Preferences", content: "Your preferences." }
    ])
    page = Capybara.string(html)
    expect(page).to have_css('#demo-tab-0[aria-selected="true"]')
    expect(page).to have_css('#demo-tab-1[aria-selected="false"]')
    expect(page).to have_css("#demo-panel-1[hidden]", visible: :all)
  end

  it "renders a labelled panel per tab with its content" do
    html = helper.render_tabs(id: "demo", tabs: [
      { label: "Profile", content: "Your profile details." },
      { label: "Preferences", content: "Your preferences." }
    ])
    page = Capybara.string(html)
    expect(page).to have_css(
      '[role="tabpanel"]#demo-panel-0[aria-labelledby="demo-tab-0"]',
      text: "Your profile details.")
    expect(page).to have_css('[role="tabpanel"]#demo-panel-1', visible: :all)
  end
end
