require "rails_helper"

# Unit spec for the combobox view helper. render_combobox resolves the
# selected value and trigger label, then renders the components/combobox
# partial; here we call it directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::ComboboxHelper, type: :helper do
  it "renders a trigger button with the selected option's label" do
    html = helper.render_combobox(name: "framework", selected: "rails",
      options: [
        { value: "rails", label: "Ruby on Rails" },
        { value: "django", label: "Django" }
      ])
    expect(Capybara.string(html)).to have_css(
      "div.select > button[aria-haspopup='listbox']", text: "Ruby on Rails")
  end

  it "shows the placeholder when nothing is selected" do
    html = helper.render_combobox(name: "framework",
      placeholder: "Select framework…",
      options: [ { value: "rails", label: "Ruby on Rails" } ])
    expect(Capybara.string(html))
      .to have_css("div.select > button", text: "Select framework…")
  end

  it "renders options in a listbox popover" do
    html = helper.render_combobox(name: "framework",
      options: [ { value: "django", label: "Django" } ])
    expect(Capybara.string(html)).to have_css(
      "div[data-popover] [role='listbox'] [role='option']", text: "Django")
  end

  it "marks only the selected option with aria-selected" do
    html = helper.render_combobox(name: "framework", selected: "rails",
      options: [
        { value: "rails", label: "Ruby on Rails" },
        { value: "django", label: "Django" }
      ])
    page = Capybara.string(html)
    expect(page).to have_css(
      "[role='option'][aria-selected='true']", text: "Ruby on Rails")
    expect(page).to have_no_css(
      "[role='option'][aria-selected='true']", text: "Django")
  end

  it "renders a search filter by default" do
    html = helper.render_combobox(name: "framework", options: [])
    expect(Capybara.string(html))
      .to have_css("div[data-popover] header input[role='combobox']")
  end

  it "omits the search filter when searchable is false" do
    html = helper.render_combobox(name: "framework", searchable: false,
      options: [])
    expect(Capybara.string(html))
      .to have_no_css("div[data-popover] header input[role='combobox']")
  end

  it "tracks the selection in a hidden input" do
    html = helper.render_combobox(name: "framework", selected: "rails",
      options: [ { value: "rails", label: "Ruby on Rails" } ])
    expect(Capybara.string(html)).to have_css(
      "input[type='hidden'][name='framework'][value='rails']", visible: :all)
  end
end
