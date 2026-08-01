module Gesso::Components
  module PatientInfoHeaderHelper
    # gender code → label shown after the name; anything outside this set
    # is treated as unknown and the suffix is omitted.
    GENDER_LABELS = { "M" => "M", "F" => "F" }.freeze

    # Renders the patient info header — the identity banner shown before
    # any clinical data. This is the public entry point: it derives the
    # avatar initials and the name + gender display, so the partial stays
    # pure markup.
    #
    # patient is a hash:
    #   first_name - given name; its first letter forms the avatar
    #   last_name  - family name; its first letter forms the avatar
    #   urn        - unit record number, shown as "UR: <urn>"
    #   gender     - "M" or "F", appended to the name as "(M)"/"(F)";
    #                any other or blank value omits the suffix
    #   dob        - date of birth, shown in the identifier row when present
    #   address    - shown in the identifier row (≥ sm screens) when present
    #
    #   render_patient_info_header(patient: { first_name:, last_name:, … })
    def render_patient_info_header(patient:)
      initials = [
        patient[:first_name].to_s[0],
        patient[:last_name].to_s[0]
      ].join.upcase

      gender_label = GENDER_LABELS[patient[:gender]]
      name = "#{patient[:first_name]} #{patient[:last_name]}"
      name += " (#{gender_label})" if gender_label.present?

      render("gesso/components/patient_info_header",
        patient:, initials:, name:)
    end
  end
end
