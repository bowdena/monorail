class Patients::SearchesController < ApplicationController
  SEARCHES_PER_MINUTE = 20

  rate_limit to: SEARCHES_PER_MINUTE, within: 1.minute,
    with: :report_too_many_searches

  def create
    @urn = params[:urn]
    @results = Patient.search(urn: @urn) if @urn.present?
  rescue Conduit::Error => error
    @failure = error
  end

  private
    def report_too_many_searches
      @throttled = true

      render :create, status: :too_many_requests
    end
end
