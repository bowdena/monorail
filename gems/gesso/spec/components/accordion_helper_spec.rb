require "rails_helper"

# Unit spec for the accordion view helper. render_accordion renders the
# gesso/components/accordion partial (a structural pass-through); here we call
# it directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::AccordionHelper, type: :helper do
  it "renders a details/summary per item with label and body" do
    html = helper.render_accordion(id: "faq", items: [
      { label: "What is an NHS number?", body: "A 10-digit number." },
      { label: "Is my data secure?", body: "Yes." }
    ])
    page = Capybara.string(html)
    expect(page).to have_css("details", count: 2)
    expect(page).to have_css("details > summary", text: "What is an NHS number?")
    expect(page).to have_text("A 10-digit number.")
  end

  it "renders a chevron icon in each summary" do
    html = helper.render_accordion(items: [
      { label: "One", body: "1" }, { label: "Two", body: "2" }
    ])
    expect(Capybara.string(html)).to have_css("details > summary svg", count: 2)
  end

  it "shares a name so only one section opens at a time by default" do
    html = helper.render_accordion(id: "faq", items: [
      { label: "One", body: "1" }, { label: "Two", body: "2" }
    ])
    expect(Capybara.string(html)).to have_css('details[name="faq"]', count: 2)
  end

  it "opens the item flagged open" do
    html = helper.render_accordion(items: [
      { label: "One", body: "1", open: true },
      { label: "Two", body: "2" }
    ])
    expect(Capybara.string(html)).to have_css("details[open]", count: 1)
  end

  it "omits the shared name when multiple sections may stay open" do
    html = helper.render_accordion(id: "faq", multiple: true, items: [
      { label: "One", body: "1" }, { label: "Two", body: "2" }
    ])
    page = Capybara.string(html)
    expect(page).to have_css("details", count: 2)
    expect(page).to have_no_css("details[name]")
  end

  it "appends caller-supplied classes to the wrapper" do
    html = helper.render_accordion(classes: "mt-4", items: [])
    expect(Capybara.string(html)).to have_css("div.accordion.mt-4")
  end
end
