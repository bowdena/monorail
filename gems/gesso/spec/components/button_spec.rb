require "rails_helper"

# Component partials are exercised through their Lookbook previews: each
# scenario is rendered via the engine's preview route and we assert on the
# returned HTML, parsed with Capybara.string so DOM matchers can query it.
# The engine is mounted in the test env (see config/routes.rb).
RSpec.describe "Button component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/button/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders the primary variant" do
    expect(render_preview("primary")).to have_css("button.btn-primary")
  end

  it "renders the destructive variant" do
    expect(render_preview("destructive")).to have_css("button.btn-destructive")
  end

  it "renders the warning variant" do
    expect(render_preview("warning")).to have_css("button.btn-warning")
  end

  it "renders the info variant" do
    expect(render_preview("info")).to have_css("button.btn-info")
  end

  it "renders the small size as a btn-sm class" do
    # size and variant combine into "btn-<size>-<variant>" when both differ
    # from default; the default-variant small button is "btn-sm-primary".
    expect(render_preview("small")).to have_css("button.btn-sm-primary")
  end

  it "disables the button when disabled" do
    expect(render_preview("disabled")).to have_css("button[disabled]")
  end

  it "shows the spinner and disables the button when loading" do
    page = render_preview("loading")
    expect(page).to have_css(".btn-spinner")
    expect(page).to have_no_css(".btn-spinner.hidden")
    expect(page).to have_css("button[disabled]")
  end
end
