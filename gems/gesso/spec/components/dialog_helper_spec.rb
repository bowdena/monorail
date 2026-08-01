require "rails_helper"

# Unit spec for the dialog view helper. render_dialog renders the
# components/dialog shell with the block as the body/footer; here we call
# it directly and assert on the HTML it returns. The dialog is closed in
# the markup, so matchers use visible: :all.
RSpec.describe Gesso::Components::DialogHelper, type: :helper do
  it "renders a native dialog shell with the drawer panel wiring" do
    html = helper.render_dialog(id: "confirm", title: "Remove team?") { "body" }
    page = Capybara.string(html)
    expect(page).to have_css(
      "dialog#confirm.dialog[data-drawer-target='panel']", visible: :all)
    expect(page).to have_css(
      "dialog[data-action='click->drawer#backdropClick']", visible: :all)
  end

  it "labels the dialog from its title and description" do
    html = helper.render_dialog(id: "confirm", title: "Remove team?",
      description: "This cannot be undone.") { "body" }
    page = Capybara.string(html)
    expect(page).to have_css(
      "dialog[aria-labelledby='confirm-title'][aria-describedby='confirm-description']",
      visible: :all)
    expect(page).to have_css("h2#confirm-title", text: "Remove team?", visible: :all)
    expect(page).to have_css("p#confirm-description", visible: :all)
  end

  it "omits aria-describedby when there is no description" do
    html = helper.render_dialog(id: "confirm", title: "Remove team?") { "body" }
    expect(Capybara.string(html))
      .to have_no_css("dialog[aria-describedby]", visible: :all)
  end

  it "renders a close button wired to the drawer controller" do
    html = helper.render_dialog(id: "confirm", title: "Remove team?",
      close_label: "Dismiss") { "body" }
    expect(Capybara.string(html)).to have_css(
      "button[aria-label='Dismiss'][data-action='click->drawer#close']",
      visible: :all)
  end

  it "renders the block as the dialog body" do
    html = helper.render_dialog(id: "confirm", title: "Remove team?") do
      "<section>Are you sure?</section>".html_safe
    end
    expect(Capybara.string(html))
      .to have_css("dialog section", text: "Are you sure?", visible: :all)
  end

  it "appends caller-supplied classes" do
    html = helper.render_dialog(id: "confirm", title: "T", classes: "max-w-lg") { "x" }
    expect(Capybara.string(html))
      .to have_css("dialog.dialog.max-w-lg", visible: :all)
  end
end
