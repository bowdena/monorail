require "rails_helper"

RSpec.describe "Main layout", type: :system do
  it "renders sidebar and header on the home page" do
    visit "/"

    expect(page).to have_css("[data-controller='sidebar']")
    expect(page).to have_css("header")
    expect(page).to have_css("main")
  end
end
