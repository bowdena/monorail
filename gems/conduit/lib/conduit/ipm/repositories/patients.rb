module Conduit
  module IPM
    module Repositories
      class Patients < Conduit::Repository[:ipm_patients]
        # Merge resolution asks about a whole match set at once, so
        # every refno reaches SQL Server in one IN list — and a
        # statement may carry at most 2100 parameters. This is the
        # ceiling on what a single search may return, not a budget
        # for round trips.
        MAX_RESULTS = 2000

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
          date_of_birth: nil, page: 1, per_page: nil)
          criteria = given_criteria(
            first_name: first_name, last_name: last_name,
            date_of_birth: date_of_birth
          )

          paged :find_all_by, criteria, page, per_page do
            ipm_patients.exact_match(criteria)
          end
        end

        def matching(first_name: nil, last_name: nil,
          date_of_birth: nil, page: 1, per_page: nil)
          criteria = given_criteria(
            first_name: first_name, last_name: last_name,
            date_of_birth: date_of_birth
          )

          paged :matching, criteria, page, per_page do
            ipm_patients.fuzzy_match(criteria)
          end
        end

        private

        # Merge resolution collapses and re-sorts matched rows, so a
        # page can only be cut once the whole match set is resolved.
        # A page the caller cannot have is only knowable by then; a
        # nonsensical one is rejected before the query runs.
        def paged(name, criteria, page, per_page, &matches)
          Page.validate_request!(page: page, per_page: per_page)

          many name, criteria.merge(page: page, per_page: per_page) do
            scope = matches.call
            refuse_oversized_search scope.count
            resolved = merge_resolver.resolve_all(scope.to_a)
            Page.of(
              mapper.call_all(resolved), page: page, per_page: per_page
            )
          end
        end

        # Counted before anything is fetched or resolved, so a search
        # this broad costs one statement. Paging cannot rescue it:
        # resolution runs over the whole match set before a page can
        # be cut, so the remedy is a narrower search.
        def refuse_oversized_search(count)
          return if count <= MAX_RESULTS

          raise Error::TooManyResults.new(
            "#{count} matches; narrow the search", source: :ipm, count: count
          )
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
