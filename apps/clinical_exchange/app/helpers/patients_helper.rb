module PatientsHelper
  def patient_name(patient)
    [ patient.first_name, patient.last_name ].compact_blank.join(" ")
  end

  def patient_date_of_birth(patient)
    patient.date_of_birth&.strftime("%d/%m/%Y")
  end
end
