# frozen_string_literal: true

# System and request specs render real pages, so the assets have to exist
# before the suite runs or the first page load times out.
# https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing
module AssetPrecompilation
  extend self

  def wanted_by_this_run?
    RSpec.world.filtered_examples.values.flatten.any? do |example|
      [ :system, :request ].include?(example.metadata[:type])
    end
  end

  # bin/dev already builds assets and would fight us over the same files.
  def development_server_running?
    system("lsof -i :3000 > /dev/null 2>&1") ||
      system("pgrep -f '^(ruby )?.*bin/dev$' > /dev/null 2>&1") ||
      system("pgrep -f '^foreman' > /dev/null 2>&1")
  end

  def invoke(task_name)
    require "rake"
    Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)
    Rake::Task[task_name].invoke
  end

  def quietly
    original_stdout = $stdout.clone
    $stdout.reopen(File.new(File::NULL, "w"))
    yield
  ensure
    $stdout.reopen(original_stdout)
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    next unless AssetPrecompilation.wanted_by_this_run?

    if AssetPrecompilation.development_server_running?
      $stdout.puts "\nDevelopment server detected. Skipping asset precompilation.\n"
      next
    end

    $stdout.puts "\nPrecompiling assets.\n"
    started_at = Time.current
    AssetPrecompilation.quietly { AssetPrecompilation.invoke("assets:precompile") }
    $stdout.puts "Finished in #{(Time.current - started_at).round(2)} seconds"
  end

  config.after(:suite) do
    next unless AssetPrecompilation.wanted_by_this_run?
    next if AssetPrecompilation.development_server_running?

    $stdout.puts "\nClobbering assets.\n"
    AssetPrecompilation.invoke("assets:clobber")
  end
end
