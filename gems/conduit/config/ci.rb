# Run using bin/ci
#
# Runs the full suite including the MSSQL integration specs, which
# expect an external MSSQL instance to already be running and
# reachable (`mise run mssql:up` starts one locally); the suite
# seeds it itself. GitHub Actions runs unit specs only (plain
# `bundle exec rspec` in the workflow); the integration tier is a
# local/pre-merge check.
#
# No Brakeman step: conduit is a plain gem, not a Rails application,
# and Brakeman only analyses Rails apps.

CI.run do
  step "Setup: gems", "bundle check || bundle install"

  step "Lint", "bundle exec rake lint"

  step "Security: Gem audit", "bundle exec bundler-audit check --update"

  step "Tests: RSpec (unit + integration)", "bundle exec rspec"
end
