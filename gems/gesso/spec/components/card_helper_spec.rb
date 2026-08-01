require "rails_helper"

# Unit spec for the card view helper. render_card renders the
# gesso/components/card partial (a structural pass-through) with the block as
# the body; here we call it directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::CardHelper, type: :helper do
  it "renders a card with a body section" do
    html = helper.render_card { "Body content" }
    expect(Capybara.string(html))
      .to have_css("div.card section", text: "Body content")
  end

  it "renders the header title and description" do
    html = helper.render_card(title: "Patient details",
      description: "NHS number 943 476 5919") { "Body" }
    page = Capybara.string(html)
    expect(page).to have_css("div.card header h2", text: "Patient details")
    expect(page).to have_css("div.card header p", text: "NHS number 943 476 5919")
  end

  it "renders the footer when given" do
    html = helper.render_card(footer: "Last updated today") { "Body" }
    expect(Capybara.string(html))
      .to have_css("div.card footer", text: "Last updated today")
  end

  it "omits the header and footer when not given" do
    html = helper.render_card { "Body" }
    page = Capybara.string(html)
    expect(page).to have_no_css("div.card header")
    expect(page).to have_no_css("div.card footer")
  end

  it "appends caller-supplied classes" do
    html = helper.render_card(classes: "lg:col-span-2") { "Body" }
    expect(Capybara.string(html)).to have_css('div.card[class~="lg:col-span-2"]')
  end

  it "yields the block as the body" do
    html = helper.render_card { "Episode summary" }
    expect(Capybara.string(html)).to have_css("section", text: "Episode summary")
  end

  it "sets the id on the card element when given" do
    html = helper.render_card(id: "version-0-4-0") { "Body" }
    expect(Capybara.string(html)).to have_css("div.card#version-0-4-0")
  end

  it "renders a custom header in place of the default one" do
    html = helper.render_card(header: tag.div("Custom", class: "flex")) { "Body" }
    page = Capybara.string(html)
    expect(page).to have_css("header div.flex", text: "Custom")
    expect(page).to have_no_css("header h2")
  end
end
