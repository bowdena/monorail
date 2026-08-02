class Patients::SearchesController < ApplicationController
  def create
    @urn = params[:urn]
    @results = Patient.search(urn: @urn) if @urn.present?
  rescue Conduit::Error => error
    @failure = error
  end
end
