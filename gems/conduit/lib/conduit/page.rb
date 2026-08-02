module Conduit
  # One page of query results, and where that page sits in the whole
  # result set. A nil per_page means the caller did not page at all:
  # everything is on page 1.
  #
  # A plain class rather than a Data, unlike conduit's other value
  # objects: including Enumerable puts it ahead of Data in the
  # ancestors, where it shadows Data#to_h with a version that raises
  # on anything but pairs.
  class Page
    include Enumerable

    attr_reader :records, :current_page, :per_page, :total_count

    class << self
      def of(records, page: 1, per_page: nil)
        validate_request!(page: page, per_page: per_page)

        paged = new(
          records: sliced(records, page, per_page),
          current_page: page,
          per_page: per_page,
          total_count: records.length
        )

        validate_range(paged)
        paged
      end

      # Public so a caller can reject a nonsense request before
      # spending the query that a page cannot be cut without.
      def validate_request!(page:, per_page:)
        raise ArgumentError, "page must be at least 1" if page < 1
        return if per_page.nil? || per_page >= 1

        raise ArgumentError, "per_page must be at least 1"
      end

      private

      # Page 1 is always valid, so a search that matched nothing
      # answers with an empty page rather than a failure.
      def validate_range(paged)
        return if paged.first_page? || paged.current_page <= paged.total_pages

        raise ArgumentError,
          "page #{paged.current_page} of #{paged.total_pages}"
      end

      def sliced(records, page, per_page)
        return records if per_page.nil?

        records.slice((page - 1) * per_page, per_page) || []
      end
    end

    def initialize(records:, current_page:, per_page:, total_count:)
      @records = records
      @current_page = current_page
      @per_page = per_page
      @total_count = total_count
    end

    def total_pages
      return 0 if total_count.zero?
      return 1 if per_page.nil?

      (total_count.to_f / per_page).ceil
    end

    def first_page?
      current_page == 1
    end

    def last_page?
      current_page >= total_pages
    end

    def next_page
      last_page? ? nil : current_page + 1
    end

    def previous_page
      first_page? ? nil : current_page - 1
    end

    def each(&block)
      records.each(&block)
    end

    def length
      records.length
    end

    def empty?
      records.empty?
    end
  end
end
