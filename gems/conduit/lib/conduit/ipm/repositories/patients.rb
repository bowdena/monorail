module Conduit
  module IPM
    module Repositories
      class Patients < Conduit::Repository[:ipm_patients]
        def by_urn(urn)
          one :by_urn, {urn: urn} do
            searched = ipm_patients.by_pasid(urn)
            resolved, merged_from = merge_resolver.resolve(searched)
            resolved ? mapper.call(resolved, merged_from: merged_from) : nil
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
            matches = ipm_patients.exact_match(criteria).to_a
            mapper.call_all(merge_resolver.resolve_all(matches))
          end
        end

        def matching(first_name: nil, last_name: nil,
          date_of_birth: nil)
          criteria = given_criteria(
            first_name: first_name, last_name: last_name,
            date_of_birth: date_of_birth
          )

          many :matching, criteria do
            matches = ipm_patients.fuzzy_match(criteria).to_a
            mapper.call_all(merge_resolver.resolve_all(matches))
          end
        end

        private

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

        def merge_resolver
          @merge_resolver ||=
            MergeResolver.new(ipm_patients, merged_patients)
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
