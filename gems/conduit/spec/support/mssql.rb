# Every :mssql example runs against the external MSSQL test instance
# (seeded by spec/support/mssql_seed_integration_tests.rb) as
# app_one's read-only login, configured here so individual specs
# don't repeat the boilerplate. Defaults match the seed SQL in
# spec/support/mssql_integration_seeds; override with the
# CONDUIT_<SOURCE>_USERNAME/_PASSWORD variables when targeting an
# instance seeded differently. Start a local one with
# `mise run mssql:up`.
module ConduitSpec
  module AppOne
    # The instance location (CONDUIT_MSSQL_HOST/PORT) is read by
    # Conduit::Sources at configure time, so an example that changes
    # it can call this again to reconnect.
    def configure_conduit!
      Conduit.reset!
      Conduit.configure do |conduit|
        conduit.application = "conduit_specs"
        conduit.source :ipm,
          username: ENV.fetch("CONDUIT_IPM_USERNAME", "conduit_app_one"),
          password: ENV.fetch("CONDUIT_IPM_PASSWORD",
            "App_one_integration1")
      end
    end
  end
end

RSpec.configure do |config|
  config.include ConduitSpec::AppOne, :mssql
  config.before(:each, :mssql) { configure_conduit! }
end
