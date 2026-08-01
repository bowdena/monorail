class Patient < ApplicationRecord
  URN_LENGTH = 7

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

    def search(urn: nil, first_name: nil, last_name: nil,
      date_of_birth: nil)
      criteria = {
        urn: urn.presence&.rjust(URN_LENGTH, "0"),
        first_name: first_name.presence,
        last_name: last_name.presence,
        date_of_birth: date_of_birth
      }.compact

      if criteria.empty?
        raise ArgumentError, "at least one criterion is required"
      end

      Results.new(records: found_in_ipm(criteria), source: :ipm)
    rescue Conduit::Error => error
      raise unless error.transient?

      Results.new(records: found_locally(criteria), source: :local)
    end

    def by_urn(urn)
      find_by(urn: urn)
    end

    def matching(first_name: nil, last_name: nil, date_of_birth: nil)
      criteria = {
        first_name: first_name.presence,
        last_name: last_name.presence,
        date_of_birth: date_of_birth
      }.compact

      if criteria.empty?
        raise ArgumentError, "at least one criterion is required"
      end

      narrowed_by(criteria)
    end

    private
      def found_in_ipm(criteria)
        patients = Conduit.ipm.patients

        if criteria[:urn]
          Array(patients.by_urn(criteria[:urn]))
        else
          Array(patients.matching(**name_criteria(criteria)))
        end
      end

      def found_locally(criteria)
        if criteria[:urn]
          Array(by_urn(criteria[:urn]))
        else
          matching(**name_criteria(criteria)).to_a
        end
      end

      def name_criteria(criteria)
        {
          first_name: criteria[:first_name],
          last_name: criteria[:last_name],
          date_of_birth: criteria[:date_of_birth]
        }
      end

      def narrowed_by(criteria)
        found = all

        if criteria[:first_name]
          found = found.where(
            "first_name ILIKE ?", fragment_of(criteria[:first_name])
          )
        end

        if criteria[:last_name]
          found = found.where(
            "last_name ILIKE ?", fragment_of(criteria[:last_name])
          )
        end

        if criteria[:date_of_birth]
          found = found.where(date_of_birth: criteria[:date_of_birth])
        end

        found
      end

      # ILIKE is Postgres' case-insensitive LIKE. Escaping means a wildcard
      # the user typed matches as the character they typed.
      def fragment_of(name)
        "%#{sanitize_sql_like(name)}%"
      end
  end
end
