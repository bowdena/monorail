# frozen_string_literal: true

# Conduit resolves iPM to a local MSSQL instance in development and test,
# so an instance left running on a developer's machine would otherwise
# answer the suite. Specs that want iPM to answer stub it themselves.
RSpec.configure do |config|
  config.before do
    unreachable = Conduit::Error::ConnectionFailed.new(
      "iPM is not served in the test environment", source: :ipm
    )
    patients = instance_double(Conduit::IPM::Repositories::Patients)

    allow(patients).to receive(:by_urn).and_raise(unreachable)
    allow(patients).to receive(:matching).and_raise(unreachable)

    allow(Conduit).to receive(:ipm)
      .and_return(instance_double(Conduit::IPM::Repos, patients: patients))
  end
end
