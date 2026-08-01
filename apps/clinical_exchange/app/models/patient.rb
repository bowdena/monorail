class Patient < ApplicationRecord
  class << self
    def remember(found)
      patient = find_or_initialize_by(urn: found.urn)

      patient.update!(
        first_name: found.first_name,
        last_name: found.last_name,
        date_of_birth: found.date_of_birth,
        gender: found.gender,
        atsi_status: found.atsi_status,
        merged_from: found.merged_from
      )

      patient
    end
  end
end
