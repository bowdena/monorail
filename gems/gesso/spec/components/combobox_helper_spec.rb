require "rails_helper"

# Unit spec for the combobox view helper. render_combobox normalises the
# selected value and renders the components/combobox partial; here we call
# it directly and assert on the HTML it returns.
RSpec.describe Gesso::Components::ComboboxHelper, type: :helper do
  it "renders the basecoat combobox input with the placeholder" do
    html = helper.render_combobox(name: "framework",
      placeholder: "Select framework…",
      options: [ { value: "rails", label: "Ruby on Rails" } ])
    expect(Capybara.string(html)).to have_css(
      "div.combobox > input[role='combobox'][placeholder='Select framework…']")
  end

  it "points the input at the listbox it controls" do
    html = helper.render_combobox(name: "framework", options: [])
    page = Capybara.string(html)
    listbox_id = page.find("[role='listbox']")[:id]
    expect(page).to have_css("input[role='combobox'][aria-controls='#{listbox_id}']")
  end

  it "renders options in a listbox popover" do
    html = helper.render_combobox(name: "framework",
      options: [ { value: "django", label: "Django" } ])
    expect(Capybara.string(html)).to have_css(
      "div[data-popover] [role='listbox'] [role='option'][data-value='django']",
      text: "Django")
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

  it "tracks the selection in a hidden input" do
    html = helper.render_combobox(name: "framework", selected: "rails",
      options: [ { value: "rails", label: "Ruby on Rails" } ])
    expect(Capybara.string(html)).to have_css(
      "div.combobox > input[type='hidden'][name='framework'][value='rails']",
      visible: :all)
  end

  it "takes a caller-supplied id" do
    html = helper.render_combobox(name: "framework", id: "framework-picker",
      options: [])
    expect(Capybara.string(html)).to have_css("div.combobox#framework-picker")
  end
end
