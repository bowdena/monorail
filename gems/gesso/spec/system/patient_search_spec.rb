require "rails_helper"

RSpec.describe "Patient search page", type: :system do
  before { visit "/patients" }

  it "renders the page with title and example patient" do
    expect(page).to have_text("Patients")
    expect(page).to have_text("Jane Smith")
    expect(page).to have_text("1234567")
  end

  it "has a URN search input" do
    expect(page).to have_field("urn")
  end

  it "has an Advanced Search tab" do
    expect(page).to have_button("Advanced Search")
  end
end
