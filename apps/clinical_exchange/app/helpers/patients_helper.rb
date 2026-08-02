module PatientsHelper
  def patient_name(patient)
    [ patient.first_name, patient.last_name ].compact_blank.join(" ")
  end

  def patient_date_of_birth(patient)
    patient.date_of_birth&.strftime("%d/%m/%Y")
  end

  # iPM describes gender in words; the patient info header appends a
  # single letter after the name, and shows nothing for anything else.
  def patient_gender_code(patient)
    patient.gender.to_s.first&.upcase
  end
end
