require "rails_helper"

# Unit spec for the button view helper. render_button owns the basecoat
# class composition and renders the gesso/components/button partial; here we
# call it directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::ButtonHelper, type: :helper do
  it "omits both attributes when the variant and size are default" do
    html = helper.render_button(variant: "default", size: "default") { "Label" }
    expect(Capybara.string(html))
      .to have_css("button.btn:not([data-variant]):not([data-size])")
  end

  it "renders the variant as data-variant" do
    html = helper.render_button(variant: "primary") { "Label" }
    expect(Capybara.string(html)).to have_css("button.btn[data-variant='primary']")
  end

  it "renders the size as data-size" do
    html = helper.render_button(variant: "default", size: "sm") { "Label" }
    expect(Capybara.string(html)).to have_css("button.btn[data-size='sm']")
  end

  it "renders size and variant as independent attributes" do
    html = helper.render_button(variant: "primary", size: "sm") { "Label" }
    expect(Capybara.string(html))
      .to have_css("button.btn[data-variant='primary'][data-size='sm']")
  end

  it "renders the icon sizes" do
    html = helper.render_button(variant: "ghost", size: "icon-sm") { "Label" }
    expect(Capybara.string(html))
      .to have_css("button.btn[data-variant='ghost'][data-size='icon-sm']")
  end

  it "passes aria attributes through to the button" do
    html = helper.render_button(size: "icon", aria: { label: "Add patient" }) { "+" }
    expect(Capybara.string(html))
      .to have_css("button.btn[aria-label='Add patient']")
  end

  it "appends caller-supplied classes" do
    html = helper.render_button(classes: "w-full") { "Label" }
    expect(Capybara.string(html)).to have_css("button.btn.w-full")
  end

  it "sets the button type" do
    html = helper.render_button(type: "submit") { "Label" }
    expect(Capybara.string(html)).to have_css("button[type=submit]")
  end

  it "disables the button when disabled" do
    html = helper.render_button(disabled: true) { "Label" }
    expect(Capybara.string(html)).to have_css("button[disabled]")
  end

  it "shows the spinner and disables the button when loading" do
    html = helper.render_button(loading: true) { "Label" }
    page = Capybara.string(html)
    expect(page).to have_css(".btn-spinner")
    expect(page).to have_no_css(".btn-spinner.hidden")
    expect(page).to have_css("button[disabled]")
  end

  it "yields the block as the label" do
    html = helper.render_button { "Save changes" }
    expect(Capybara.string(html)).to have_css("button", text: "Save changes")
  end

  it "raises ArgumentError for an unknown variant" do
    expect { helper.render_button(variant: "bogus") { "Label" } }
      .to raise_error(ArgumentError, /variant/)
  end

  it "raises ArgumentError for an unknown size" do
    expect { helper.render_button(size: "huge") { "Label" } }
      .to raise_error(ArgumentError, /size/)
  end
end
