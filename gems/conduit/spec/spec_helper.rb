require "conduit"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Everything under spec/integration needs the external MSSQL test
  # instance (seeded by the suite itself; start one with
  # `mise run mssql:up`): location implies the :mssql tag. Those
  # specs run by default and are skipped only when asked:
  #   CONDUIT_SKIP_MSSQL=1 bundle exec rspec
  config.define_derived_metadata(file_path: %r{spec/integration/}) do |meta|
    meta[:mssql] = true
  end
  if ENV["CONDUIT_SKIP_MSSQL"]
    config.filter_run_excluding :mssql
    ENV["CONDUIT_LOGIN_TIMEOUT"] ||= "1"
  end
end
