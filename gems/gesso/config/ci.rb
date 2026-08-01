# Run using bin/ci

CI.run do
  step "Setup: gems", "bundle check || bundle install"
  step "Setup: JS dependencies", "cd spec/dummy && yarn install --immutable"

  step "Lint", "bundle exec rake lint"

  step "Security: Gem audit", "bundle exec bundler-audit check --update"
  step "Security: Brakeman code analysis", "bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: RSpec", "bundle exec rspec"
end
