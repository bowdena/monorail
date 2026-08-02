class Patients::SearchesController < ApplicationController
  SEARCHES_PER_MINUTE = 20

  rate_limit to: SEARCHES_PER_MINUTE, within: 1.minute,
    with: :report_too_many_searches

  def create
    criteria = search_criteria

    case
    when @invalid_date
      nil
    when criteria.empty?
      @unsearchable = true
    else
      @results = Patient.search(**criteria)
    end
  rescue Conduit::Error => error
    @failure = error
  end

  private
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

      render :create, status: :too_many_requests
    end
end
