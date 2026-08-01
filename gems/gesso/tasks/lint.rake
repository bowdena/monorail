ERB_GLOBS = "'app/views/**/*.erb' 'spec/dummy/app/views/**/*.erb'"

namespace :lint do
  namespace :autocorrect do
    desc "Autocorrect Ruby offenses"
    task :rubocop do
      sh "bundle exec rubocop --autocorrect"
    end

    desc "Autocorrect ERB lint offenses"
    task :"herb-lint" do
      sh "bundle exec herb lint --fix #{ERB_GLOBS}"
    end

    desc "Autocorrect ERB formatting"
    task :herb do
      sh "bundle exec herb format #{ERB_GLOBS}"
    end
  end

  desc "Autocorrect all lint offenses"
  task autocorrect: %w[
    lint:autocorrect:rubocop
    lint:autocorrect:herb-lint
    lint:autocorrect:herb
  ]
end

desc "Run all lint checks (rubocop, herb lint, herb format)"
task :lint do
  sh "bundle exec rubocop"
  sh "bundle exec herb lint #{ERB_GLOBS}"
  sh "bundle exec herb format --check #{ERB_GLOBS}"
end
