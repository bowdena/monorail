require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Alert component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/alert/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders the default variant with a title and body" do
    page = render_preview("default")
    expect(page).to have_css("div.alert")
    expect(page).to have_css("h2", text: "Heads up")
    expect(page).to have_text("Something you should know about.")
  end

  it "renders every variant as data-variant on the base alert class" do
    %w[destructive warning critical info].each do |variant|
      expect(render_preview(variant))
        .to have_css("div.alert[data-variant='#{variant}']")
    end
  end

  it "renders an inline svg when an icon is given" do
    expect(render_preview("with_icon")).to have_css("svg")
  end

  it "omits the icon when none is given" do
    expect(render_preview("default")).to have_no_css("svg")
  end
end
