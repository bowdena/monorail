module Conduit
  module IPM
    module Repositories
      class Patients < Conduit::Repository[:ipm_patients]
        def by_urn(urn)
          one :by_urn, {urn: urn} do
            resolve_patient(ipm_patients.find_by_urn(urn))
          end
        end

        def by_urn!(urn)
          by_urn(urn) or raise Error::NotFound.new(
            "no patient with urn #{urn}", source: :ipm
          )
        end

        def find_all_by(first_name: nil, last_name: nil,
          date_of_birth: nil)
          criteria = given_criteria(
            first_name: first_name, last_name: last_name,
            date_of_birth: date_of_birth
          )

          many :find_all_by, criteria do
            mapper.call_all(ipm_patients.exact_match(criteria).to_a)
          end
        end

        def matching(first_name: nil, last_name: nil,
          date_of_birth: nil)
          criteria = given_criteria(
            first_name: first_name, last_name: last_name,
            date_of_birth: date_of_birth
          )

          many :matching, criteria do
            mapper.call_all(ipm_patients.fuzzy_match(criteria).to_a)
          end
        end

        private

        # The patient a requested row leads to now, reporting the URN
        # that was requested when resolution moved to another record.
        # Nil when nothing was found, or when the merges end
        # somewhere no longer active.
        def resolve_patient(requested_patient)
          return nil unless requested_patient

          survivor = surviving_patient(requested_patient)
          return nil unless survivor

          same_patient = requested_patient[:urn] == survivor[:urn]
          merged_from = same_patient ? nil : requested_patient[:urn]

          mapper.call(survivor, merged_from: merged_from)
        end

        # The given patient unless they were superseded and their
        # merges lead somewhere, in which case the patient at the end
        # of them.
        def surviving_patient(patient)
          return patient unless superseded?(patient)

          refno = surviving_refno(patient[:patnt_refno])
          refno ? ipm_patients.active_by_refno(refno) : patient
        end

        # The reference a chain of merges ends at, or nil when
        # nothing points onwards. Merges chain, so one hop is not
        # enough; corrupt data can point in a circle, so a reference
        # already seen ends the walk.
        def surviving_refno(superseded_refno)
          seen = [superseded_refno]
          while (next_refno = merged_patients.survivor_for(seen.last))
            break if seen.include?(next_refno)
            seen << next_refno
          end
          return nil if seen.length == 1

          seen.last
        end

        # iPM calls the superseded side of a merge the minor record,
        # hence the column name, and leaves it active. Compared
        # case-insensitively to match the column's collation.
        def superseded?(patient)
          patient[:merge_minor_flag].casecmp?("Y")
        end

        def source
          :ipm
        end

        def resource_name
          "ipm_patients"
        end

        def record_identifier(record)
          record.urn
        end

        def ipm_patients
          relation(:ipm_patients)
        end

        def merged_patients
          relation(:ipm_merged_patients)
        end

        def mapper
          @mapper ||= PatientMapper.new(
            ReferenceLookup.new(relation(:ipm_reference_values))
          )
        end

        # Blank criteria are ignored; all blank is a caller bug —
        # the PHP this replaces matched the entire table instead.
        def given_criteria(first_name:, last_name:, date_of_birth:)
          criteria = {
            first_name: presence(first_name),
            last_name: presence(last_name),
            date_of_birth: date_of_birth
          }.compact

          if criteria.empty?
            raise ArgumentError, "at least one criterion is required"
          end

          criteria
        end

        # ActiveSupport's presence is unavailable here — conduit
        # loads only the notifications slice.
        def presence(value)
          value.to_s.strip.empty? ? nil : value
        end
      end
    end
  end
end
