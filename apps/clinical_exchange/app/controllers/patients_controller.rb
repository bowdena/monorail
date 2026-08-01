class PatientsController < ApplicationController
  def index
    @results = Patient.search(urn: params[:urn]) if params[:urn].present?
  end
end
