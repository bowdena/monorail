class Patients::SearchesController < ApplicationController
  SEARCHES_PER_MINUTE = 20
  RESULTS_PER_PAGE = 25

  rate_limit to: SEARCHES_PER_MINUTE, within: 1.minute,
    with: :report_too_many_searches

  # Searching by name, which can match more patients than fit on a page.
  def show
    search
  end

  # Searching by urn, which matches at most one patient. It stays a POST
  # so the identifier never appears in a url.
  def create
    search

    render :show
  end

  private
    def search
      criteria = search_criteria

      case
      when @invalid_date
        nil
      when criteria.empty?
        @unsearchable = true
      else
        @results = Patient.search(**criteria, page: requested_page,
          per_page: RESULTS_PER_PAGE)
      end
    rescue Conduit::Error => error
      @failure = error
    end

    # A page below one only arrives from a hand-edited url, and reads as
    # a request for the beginning.
    def requested_page
      [ params[:page].to_i, 1 ].max
    end

    CRITERIA = %i[ urn first_name last_name date_of_birth ].freeze

    # Sliced before permitting: a browser also posts the forgery token,
    # and permitting the whole hash reports it as unpermitted on every
    # search.
    def search_criteria
      criteria = params.slice(*CRITERIA).permit(*CRITERIA)
        .to_h.symbolize_keys.compact_blank

      @urn = criteria[:urn]

      return criteria.slice(:urn) if @urn.present?

      criteria.merge(date_of_birth: date_of_birth(criteria)).compact_blank
    end

    # Dates are read day first, as they are written here. A browser's own
    # date field would render in the machine's locale, which would show
    # some staff month first for the same stored value.
    def date_of_birth(criteria)
      return if criteria[:date_of_birth].blank?

      Date.strptime(criteria[:date_of_birth].tr("-.", "//"), "%d/%m/%Y")
    rescue Date::Error
      @invalid_date = true

      nil
    end

    def report_too_many_searches
      @throttled = true

      render :show, status: :too_many_requests
    end
end
