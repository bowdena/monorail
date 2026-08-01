require "rails_helper"

# Unit spec for the pagination view helper. render_pagination renders a
# handed-in page window (it does no page maths); here we call it directly
# and assert on the HTML it returns.
RSpec.describe Gesso::Components::PaginationHelper, type: :helper do
  it "renders a labelled pagination nav with a page list" do
    html = helper.render_pagination(
      pages: [ { number: 1, path: "?page=1", current: true } ])
    expect(Capybara.string(html)).to have_css("nav[aria-label='Pagination'] ul li")
  end

  it "marks the current page with btn-icon-outline and aria-current" do
    html = helper.render_pagination(
      pages: [ { number: 3, path: "?page=3", current: true } ])
    expect(Capybara.string(html))
      .to have_css("a.btn-icon-outline[aria-current='page']", text: "3")
  end

  it "renders non-current pages with btn-icon-ghost and no aria-current" do
    html = helper.render_pagination(
      pages: [ { number: 4, path: "?page=4", current: false } ])
    page = Capybara.string(html)
    expect(page).to have_css("a.btn-icon-ghost", text: "4")
    expect(page).to have_no_css("a[aria-current]")
  end

  it "renders an ellipsis for a :gap entry" do
    html = helper.render_pagination(pages: [ :gap ])
    page = Capybara.string(html)
    expect(page).to have_css("span[aria-hidden='true']")
    expect(page).to have_css("span.sr-only", text: "More pages")
  end

  it "renders the previous link when a path is given" do
    html = helper.render_pagination(previous: { path: "?page=1" })
    expect(Capybara.string(html))
      .to have_css("a[aria-label='Go to previous page']")
  end

  it "renders the next link when a path is given" do
    html = helper.render_pagination(next_page: { path: "?page=2" })
    expect(Capybara.string(html))
      .to have_css("a[aria-label='Go to next page']")
  end

  it "omits the previous link when previous is nil" do
    html = helper.render_pagination(
      pages: [ { number: 1, path: "?page=1", current: true } ])
    expect(Capybara.string(html))
      .to have_no_css("a[aria-label='Go to previous page']")
  end

  it "omits the next link when next_page is nil" do
    html = helper.render_pagination(
      pages: [ { number: 1, path: "?page=1", current: true } ])
    expect(Capybara.string(html))
      .to have_no_css("a[aria-label='Go to next page']")
  end
end
