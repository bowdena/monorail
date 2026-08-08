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

        # The patient a searched row leads to now, reporting the URN
        # that was searched when resolution moved to another record.
        # Nil when the trail ends somewhere no longer active.
        def current_record_for(searched)
          current = current_row(searched)
          return nil unless current

          moved_on = current[:urn] != searched[:urn]
          mapper.call(current, merged_from: moved_on ? searched[:urn] : nil)
        end

        # The searched row itself unless it was merged away and the
        # trail leads somewhere, in which case the row it ends at.
        def current_row(searched)
          return searched unless merged_away?(searched)

          refno = merge_trail_end(searched[:patnt_refno])
          refno ? ipm_patients.active_by_refno(refno) : searched
        end

        # The reference the merge trail ends at, or nil when nothing
        # points onwards. Merges chain, so one hop is not enough;
        # corrupt data can point in a circle, so a reference already
        # seen ends the walk.
        def merge_trail_end(patnt_refno)
          seen = [patnt_refno]
          while (target = merged_patients.target_for(seen.last))
            break if seen.include?(target)
            seen << target
          end
          return nil if seen.length == 1

          seen.last
        end

        # iPM flags the losing side of a merge and leaves it active.
        # Compared case-insensitively to match the column's collation.
        def merged_away?(searched)
          searched[:merge_minor_flag].casecmp?("Y")
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
