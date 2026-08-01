# frozen_string_literal: true

require "database_cleaner/active_record"

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:deletion)
  end

  config.around(:each) do |example|
    # System specs commit their data so the browser thread can see it, so
    # they need deletion. Everything else rolls back, which is as fast as
    # use_transactional_fixtures.
    system_spec = example.metadata[:type] == :system
    DatabaseCleaner.strategy = system_spec ? :deletion : :transaction
    DatabaseCleaner.cleaning { example.run }
  end
end
