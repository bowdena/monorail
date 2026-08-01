# frozen_string_literal: true

# https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing

# Precompile assets before specs that render through the app (system specs,
# and request specs whose layout links the compiled CSS/JS), so the browser
# sees the gesso components styled and `bundle exec rspec` is green from a
# clean checkout with no manual build. assets:precompile is enhanced by
# tailwindcss-rails and jsbundling-rails, so it drives the real build
# pipeline. Skipped for helper-unit runs and when a dev server is running.
#
# This file belongs to the app, not to gesso — edit it freely. The
# installer will not replace it or add a second hook alongside it.
module AssetPrecompilation
  extend self

  def needed?
    RSpec.world.filtered_examples.values.flatten.any? do |example|
      %i[ system request ].include?(example.metadata[:type])
    end
  end

  # Only a dev server for THIS app makes skipping safe — its watchers own
  # app/assets/builds. Machine-wide checks (port 3000, any foreman) let
  # another monorepo app's server suppress this app's build. The server
  # pid file lives under this Rails.root, so it is inherently scoped.
  def dev_server_running?
    pid_file = Rails.root.join("tmp/pids/server.pid")
    return false unless pid_file.exist?

    Process.kill(0, File.read(pid_file).to_i)
    true
  rescue Errno::ESRCH, ArgumentError
    false
  end

  def invoke(task_name)
    require "rake"
    Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)
    # jsbundling runs `yarn build` from the process CWD, which is not
    # guaranteed to be where package.json lives.
    Dir.chdir(Rails.root) { Rake::Task[task_name].invoke }
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
    next unless AssetPrecompilation.needed?

    if AssetPrecompilation.dev_server_running?
      $stdout.puts "\n⚠️  Development server detected. Skipping asset precompilation.\n"
      next
    end

    $stdout.puts "\n🐢  Precompiling assets.\n"
    started_at = Time.current
    AssetPrecompilation.quietly { AssetPrecompilation.invoke("assets:precompile") }
    $stdout.puts "Finished in #{(Time.current - started_at).round(2)} seconds"
  end

  config.after(:suite) do
    next unless AssetPrecompilation.needed?
    next if AssetPrecompilation.dev_server_running?

    $stdout.puts "\n🗑️  Clobbering assets.\n"
    AssetPrecompilation.invoke("assets:clobber")
  end
end
