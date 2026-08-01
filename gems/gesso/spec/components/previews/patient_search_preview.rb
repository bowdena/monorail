# Previews for the patient info header composite.
#
# Each scenario renders through render_patient_info_header
# (Gesso::Components::PatientInfoHeaderHelper) via the shared
# patient_search_preview/preview template.
#
# @label Patient Search
class PatientSearchPreview < Lookbook::Preview
  # Usage rules: [Patient search design guidance](/lookbook/pages/components/patient_search)
  def default
    preview(
      urn: "1234567",
      first_name: "Jane",
      last_name: "Smith",
      dob: "15 Mar 1985",
      gender: "F",
      address: "123 Main St, Sydney NSW 2000"
    )
  end

  def male_patient
    preview(
      urn: "9876543",
      first_name: "John",
      last_name: "Doe",
      dob: "22 Jul 1970",
      gender: "M",
      address: "456 King St, Melbourne VIC 3000"
    )
  end

  def minimal
    preview(
      urn: "0000001",
      first_name: "Alex",
      last_name: "Taylor",
      dob: nil,
      gender: nil,
      address: nil
    )
  end

  private
    def preview(**patient)
      render_with_template(template: "patient_search_preview/preview",
        locals: { patient: })
    end
end
