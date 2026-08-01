require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"

abort("Running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
