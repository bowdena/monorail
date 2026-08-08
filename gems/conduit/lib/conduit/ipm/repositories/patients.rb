module Conduit
  module IPM
    module Repositories
      class Patients < Conduit::Repository[:ipm_patients]
        def by_urn(urn)
          one :by_urn, {urn: urn} do
            searched = ipm_patients.by_pasid(urn)
            searched && current_record_for(searched)
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

        # The record a searched row leads to now. A row that was
        # merged away resolves to the record it was merged into and
        # reports the URN that was searched; nil when the trail ends
        # somewhere no longer active.
        def current_record_for(searched)
          refno = current_refno(searched[:patnt_refno])
          if refno == searched[:patnt_refno]
            return mapper.call(searched, merged_from: nil)
          end

          current = ipm_patients.active_by_refno(refno)
          current && mapper.call(current, merged_from: searched[:urn])
        end

        # Follows the merge trail to the reference at its end. Merges
        # chain, so one hop is not enough; corrupt data can point in a
        # circle, so a reference already seen ends the walk.
        def current_refno(patnt_refno)
          seen = [patnt_refno]
          while (target = merged_patients.latest_target(seen.last))
            break if seen.include?(target)
            seen << target
          end
          seen.last
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
