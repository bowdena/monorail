require "rails_helper"

# Unit spec for the stat card view helper. render_stat_card validates
# change_type and owns the badge-variant composition, then renders the
# gesso/components/stat_card partial; here we call it directly and assert on
# the HTML it returns.
RSpec.describe Gesso::Components::StatCardHelper, type: :helper do
  it "renders the title and value inside a card" do
    html = helper.render_stat_card(title: "Total patients", value: "1,284")
    page = Capybara.string(html)
    expect(page).to have_css("div.card")
    expect(page).to have_text("Total patients")
    expect(page).to have_css(".stat-card-value", text: "1,284")
  end

  it "maps a positive change to a success badge" do
    html = helper.render_stat_card(value: "1", change: "+12%",
                                   change_type: "positive")
    expect(Capybara.string(html))
      .to have_css("span.badge[data-variant='success']", text: "+12%")
  end

  it "maps a negative change to a destructive badge" do
    html = helper.render_stat_card(value: "1", change: "-4%",
                                   change_type: "negative")
    expect(Capybara.string(html))
      .to have_css("span.badge[data-variant='destructive']", text: "-4%")
  end

  it "maps a neutral change to a secondary badge" do
    html = helper.render_stat_card(value: "1", change: "0%",
                                   change_type: "neutral")
    expect(Capybara.string(html))
      .to have_css("span.badge[data-variant='secondary']", text: "0%")
  end

  it "omits the change badge when no change is given" do
    html = helper.render_stat_card(title: "Beds available", value: "56")
    expect(Capybara.string(html)).to have_no_css("span.badge")
  end

  it "renders a leading icon when given" do
    html = helper.render_stat_card(value: "1", icon: "users")
    expect(Capybara.string(html)).to have_css("svg")
  end

  it "appends caller-supplied classes to the card" do
    html = helper.render_stat_card(value: "1", classes: "col-span-2")
    expect(Capybara.string(html)).to have_css("div.card.stat-card.col-span-2")
  end

  it "raises ArgumentError for an unknown change_type" do
    expect { helper.render_stat_card(value: "1", change_type: "bogus") }
      .to raise_error(ArgumentError, /change_type/)
  end
end
