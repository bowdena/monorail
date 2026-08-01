require "rails_helper"

RSpec.describe "Login page", type: :system do
  it "renders login card with sign-in button" do
    visit "/login"

    expect(page).to have_css(".card")
    expect(page).to have_button("Sign in with Microsoft")
    expect(page).to have_text("Sign in with your organisation account")
  end
end
