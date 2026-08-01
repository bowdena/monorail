require "rails_helper"

# Unit spec for the patient info header view helper.
# render_patient_info_header derives the avatar initials and the name +
# gender display, then renders the partial; here we call it directly and
# assert on the HTML it returns.
RSpec.describe Gesso::Components::PatientInfoHeaderHelper, type: :helper do
  it "renders the avatar initials from the patient name" do
    html = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", urn: "1234567" })
    expect(Capybara.string(html)).to have_css(".user-avatar", text: "JS")
  end

  it "shows the name with a gender suffix for a known gender" do
    html = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", gender: "F", urn: "1234567" })
    expect(Capybara.string(html)).to have_text("Jane Smith (F)")
  end

  it "omits the gender suffix when the gender is unknown" do
    html = helper.render_patient_info_header(patient: {
      first_name: "Alex", last_name: "Taylor", gender: nil, urn: "0000001" })
    page = Capybara.string(html)
    expect(page).to have_text("Alex Taylor")
    expect(page).to have_no_text("Alex Taylor (")
  end

  it "renders the UR number" do
    html = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", urn: "1234567" })
    expect(Capybara.string(html)).to have_text("UR: 1234567")
  end

  it "renders the DOB when present and omits it when blank" do
    with_dob = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", urn: "1", dob: "15 Mar 1985" })
    without_dob = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", urn: "1", dob: nil })
    expect(Capybara.string(with_dob)).to have_text("DOB: 15 Mar 1985")
    expect(Capybara.string(without_dob)).to have_no_text("DOB:")
  end

  it "renders the address when present and omits it when blank" do
    with_address = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", urn: "1",
      address: "123 Main St" })
    without_address = helper.render_patient_info_header(patient: {
      first_name: "Jane", last_name: "Smith", urn: "1", address: nil })
    expect(Capybara.string(with_address)).to have_text("123 Main St")
    expect(Capybara.string(without_address)).to have_no_text("123 Main St")
  end
end
