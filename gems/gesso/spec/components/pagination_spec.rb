require "rails_helper"

# Rendered through the Lookbook preview route; see button_spec for the
# pattern and config/routes.rb for the test-env engine mount. The body
# is parsed with Capybara.string so DOM matchers can query it.
RSpec.describe "Pagination component", type: :request do
  def render_preview(scenario)
    get "/lookbook/preview/pagination/#{scenario}"
    expect(response).to have_http_status(:ok)
    Capybara.string(response.body)
  end

  it "renders a labelled pagination nav with a page list" do
    page = render_preview("default")
    expect(page).to have_css("nav[aria-label='Pagination'] ul")
  end

  it "marks the current page with the outline variant and aria-current" do
    page = render_preview("default")
    expect(page).to have_css(
      "a.btn[data-variant='outline'][data-size='icon'][aria-current='page']",
      text: "3"
    )
  end

  it "renders non-current pages with the ghost variant" do
    page = render_preview("default")
    expect(page)
      .to have_css("a.btn[data-variant='ghost'][data-size='icon']", text: "4")
    expect(page).to have_no_css("a.btn[data-variant='ghost'][aria-current]")
  end

  it "renders an ellipsis for each :gap in the window" do
    page = render_preview("default")
    expect(page).to have_css("span[aria-hidden='true']", count: 2)
    expect(page).to have_css("span.sr-only", text: "More pages")
  end

  it "renders previous and next links when paths are given" do
    page = render_preview("default")
    expect(page).to have_css("a[aria-label='Go to previous page']")
    expect(page).to have_css("a[aria-label='Go to next page']")
  end

  it "omits the previous link on the first page" do
    page = render_preview("first_page")
    expect(page).to have_no_css("a[aria-label='Go to previous page']")
    expect(page).to have_css("a[aria-label='Go to next page']")
  end

  it "omits the next link on the last page" do
    page = render_preview("last_page")
    expect(page).to have_css("a[aria-label='Go to previous page']")
    expect(page).to have_no_css("a[aria-label='Go to next page']")
  end
end
