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
      date_of_birth: nil, page: 1, per_page: nil)
      criteria = {
        urn: urn.presence&.rjust(URN_LENGTH, "0"),
        first_name: first_name.presence,
        last_name: last_name.presence,
        date_of_birth: date_of_birth
      }.compact

      if criteria.empty?
        raise ArgumentError, "at least one criterion is required"
      end

      found_on_page(criteria, page: page, per_page: per_page)
    end

    # A selection is looked up again rather than taken from the page it
    # was made on: the browser is free to post any urn, and what gets
    # kept has to be what the source holds. While iPM is unreachable the
    # patient is already here, or cannot be confirmed at all.
    def remembered(urn)
      found = search(urn: urn).records.first

      raise ActiveRecord::RecordNotFound, "no patient with urn #{urn}" if found.nil?

      found.is_a?(self) ? found : remember(found)
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
      # Always answers with a page that exists. A link made when the
      # search had more pages asks for one that has since gone, and the
      # first page is a better answer than a failure. The results say
      # which page they hold, so a caller can tell the clinician.
      #
      # The two sources disagree on how they refuse: conduit raises,
      # while a slice past the end of the local table is simply empty.
      def found_on_page(criteria, page:, per_page:)
        found = found_anywhere(criteria, page: page, per_page: per_page)

        return found unless page > found.total_pages &&
          found.total_pages.positive?

        found_anywhere(criteria, page: 1, per_page: per_page)
      rescue ArgumentError
        found_anywhere(criteria, page: 1, per_page: per_page)
      end

      def found_anywhere(criteria, page:, per_page:)
        found_in_ipm(criteria, page: page, per_page: per_page)
      rescue Conduit::Error => error
        raise unless error.transient?

        found_locally(criteria, page: page, per_page: per_page)
      end

      # A urn matches at most one patient, so it is answered whole and
      # sits on a page of its own. Only a name search is paged.
      def found_in_ipm(criteria, page:, per_page:)
        patients = Conduit.ipm.patients

        if criteria[:urn]
          only_page(Array(patients.by_urn(criteria[:urn])), source: :ipm)
        else
          found = patients.matching(**name_criteria(criteria),
            page: page, per_page: per_page)

          Results.new(records: found.records, source: :ipm,
            current_page: found.current_page, per_page: found.per_page,
            total_count: found.total_count)
        end
      end

      def found_locally(criteria, page:, per_page:)
        if criteria[:urn]
          only_page(Array(by_urn(criteria[:urn])), source: :local)
        else
          page_of(matching(**name_criteria(criteria)), page: page,
            per_page: per_page)
        end
      end

      def only_page(records, source:)
        Results.new(records: records, source: source, current_page: 1,
          per_page: nil, total_count: records.length)
      end

      # Counted and sliced in the database rather than in Ruby: this
      # table grows by a row for every patient ever looked up here.
      def page_of(found, page:, per_page:)
        total_count = found.count
        records = per_page ? found.offset((page - 1) * per_page)
          .limit(per_page) : found

        Results.new(records: records.to_a, source: :local,
          current_page: page, per_page: per_page, total_count: total_count)
      end

      def name_criteria(criteria)
        {
          first_name: criteria[:first_name],
          last_name: criteria[:last_name],
          date_of_birth: criteria[:date_of_birth]
        }
      end

      # Ordered as conduit orders iPM's matches, and for the same reason
      # a paged query needs any order at all: without one the database
      # may repeat a patient on one page and skip them on another.
      def narrowed_by(criteria)
        found = order(:last_name, :first_name)

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
