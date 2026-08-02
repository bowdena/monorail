require "rails_helper"

RSpec.describe "Conduit configuration" do
  it "identifies this application to conduit" do
    expect(Conduit.configuration.application).to eq("clinical_exchange")
  end

  it "configures the ipm source" do
    expect(Conduit.configuration).to be_configured(:ipm)
  end

  it "logs the queries conduit runs" do
    logged = []
    allow(Rails.logger).to receive(:info) { |message| logged << message }

    ActiveSupport::Notifications.instrument(
      "query.conduit",
      application: "clinical_exchange", source: :ipm,
      resource: "ipm_patients", name: :by_urn, params: { urn: "0700003" },
      row_count: 1, record_ids: [ "0700003" ], error: nil
    )

    expect(logged.last).to include("ipm_patients", "0700003")
  end
end
