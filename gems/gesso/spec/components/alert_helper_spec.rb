require "rails_helper"

# Unit spec for the alert view helper. render_alert validates the variant
# and owns the basecoat class composition, then renders the
# gesso/components/alert partial; here we call it directly and assert on the
# HTML it returns.
RSpec.describe Gesso::Components::AlertHelper, type: :helper do
  it "renders the base alert class for the default variant" do
    html = helper.render_alert(title: "Heads up") { "Body" }
    expect(Capybara.string(html)).to have_css("div.alert[role=alert]")
  end

  it "renders the destructive variant as alert-destructive" do
    html = helper.render_alert(variant: "destructive") { "Body" }
    expect(Capybara.string(html)).to have_css("div.alert-destructive")
  end

  it "layers clinical variants on the base alert class" do
    %w[warning critical info].each do |variant|
      html = helper.render_alert(variant:) { "Body" }
      expect(Capybara.string(html)).to have_css("div.alert.alert-#{variant}")
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
