require "rails_helper"

# Unit spec for the alert view helper. render_alert validates the variant
# and resolves it to what basecoat expects, then renders the
# gesso/components/alert partial; here we call it directly and assert on the
# HTML it returns.
RSpec.describe Gesso::Components::AlertHelper, type: :helper do
  it "omits the variant attribute for the default variant" do
    html = helper.render_alert(title: "Heads up") { "Body" }
    expect(Capybara.string(html))
      .to have_css("div.alert[role=alert]:not([data-variant])")
  end

  it "renders every other variant as data-variant" do
    %w[destructive warning critical info].each do |variant|
      html = helper.render_alert(variant:) { "Body" }
      expect(Capybara.string(html))
        .to have_css("div.alert[data-variant='#{variant}']")
    end
  end

  it "renders the title in an h2" do
    html = helper.render_alert(title: "Heads up") { "Body" }
    expect(Capybara.string(html)).to have_css("h2", text: "Heads up")
  end

  it "omits the title when none is given" do
    html = helper.render_alert { "Body" }
    expect(Capybara.string(html)).to have_no_css("h2")
  end

  it "renders an inline svg when an icon is given" do
    html = helper.render_alert(icon: "icons/info") { "Body" }
    expect(Capybara.string(html)).to have_css("svg")
  end

  it "omits the icon when none is given" do
    html = helper.render_alert { "Body" }
    expect(Capybara.string(html)).to have_no_css("svg")
  end

  it "yields the block as the alert body" do
    html = helper.render_alert { "Results are stale." }
    expect(Capybara.string(html)).to have_css("section", text: "Results are stale.")
  end

  it "appends caller-supplied classes" do
    html = helper.render_alert(classes: "mt-4") { "Body" }
    expect(Capybara.string(html)).to have_css("div.alert.mt-4")
  end

  it "raises ArgumentError for an unknown variant" do
    expect { helper.render_alert(variant: "bogus") { "Body" } }
      .to raise_error(ArgumentError, /variant/)
  end
end
