class PatientsController < ApplicationController
  SELECTIONS_PER_MINUTE = 20

  rate_limit to: SELECTIONS_PER_MINUTE, within: 1.minute,
    with: :report_too_many_selections, only: :create

  def index
  end

  def show
    @patient = Patient.find(params[:id])
  end

  def create
    redirect_to Patient.remembered(params[:urn])
  end

  private
    def report_too_many_selections
      redirect_to patients_path,
        alert: "Too many lookups. Wait a minute, then try again."
    end
end
