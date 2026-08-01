require "rails_helper"

# Regression: the layout linked stylesheets with Propshaft's :app, which
# includes every CSS under app/assets — among them the build *input*
# tailwindcss-rails generates for the engine
# (app/assets/builds/tailwind/gesso.css). That file's auto-generated
# @import is an absolute filesystem path, so the browser requested it as
# a URL and 404ed on every page.
RSpec.describe "Assets", type: :system do
  it "loads every asset the layout links" do
    visit "/"

    failures = page.driver.browser.logs.get(:browser)
      .select { |entry| entry.level == "SEVERE" }
      .map(&:message)

    expect(failures).to be_empty
  end

  it "does not link the engine's tailwind build input" do
    visit "/"

    expect(page).to have_no_css("link[href*='tailwind/gesso']", visible: :all)
  end
end
