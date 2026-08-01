# Runs a linter and stops the whole rake run when it reports offences,
# so `bin/ci` fails on the first linter that is unhappy.
def run_linter(name, command, failure_message)
  puts "Running #{name}"
  abort(failure_message) unless system(command)
end

desc "Run every linter and fail if any reports an offence"
task lint: [ "lint:herb:check", "lint:herb:formatcheck", "lint:rubocop:check" ]

namespace :lint do
  desc "Fix every offence the linters can fix on their own"
  task autocorrect: [ "lint:herb:autocorrect", "lint:rubocop:autocorrect" ]

  namespace :herb do
    desc "Check ERB templates for offences"
    task :check do
      run_linter "herb:lint", "yarn herb:lint", "Herb linting failed."
    end

    desc "Check ERB templates are formatted"
    task :formatcheck do
      run_linter "herb:format:check", "yarn herb:format:check",
        "Herb format check failed."
    end

    desc "Reformat ERB templates in place"
    task :autocorrect do
      run_linter "herb:format", "yarn herb:format", "Herb autocorrect failed."
    end
  end

  namespace :rubocop do
    desc "Check Ruby for offences"
    task :check do
      run_linter "rubocop", "bundle exec rubocop", "RuboCop failed."
    end

    desc "Fix the Ruby offences RuboCop can fix on its own"
    task :autocorrect do
      run_linter "rubocop (autocorrect)", "bundle exec rubocop -a",
        "RuboCop autocorrect failed."
    end
  end
end
