# frozen_string_literal: true

# https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing
# https://github.com/anycable/anycable_rails_demo/blob/master/spec/system/support/precompile_assets.rb

# Precompile the dummy host's assets before running specs that render
# through the app. System specs drive a real browser, and the Lookbook
# request specs render previews in a layout that links the compiled CSS/JS;
# both 500 if app/assets/builds is empty. assets:precompile is enhanced by
# tailwindcss-rails (tailwindcss:build) and jsbundling-rails
# (javascript:build), so this drives the project's real build pipeline
# rather than hardcoding commands — making `bundle exec rspec` green from a
# clean checkout with no manual steps. Skipped when only helper-unit specs
# run (no Node needed) or when a dev server is already building assets.
RSpec.configure do |config|
  def needs_assets?
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

  config.before(:suite) do
    next unless needs_assets?

    if dev_server_running?
      $stdout.puts "\n⚠️  Development server detected. Skipping asset precompilation.\n"
      next
    end

    $stdout.puts "\n🐢  Precompiling assets.\n"
    original_stdout = $stdout.clone
    start = Time.current
    begin
      $stdout.reopen(File.new(File::NULL, "w"))

      require "rake"
      Rails.application.load_tasks unless Rake::Task.task_defined?("assets:precompile")
      # jsbundling runs `yarn build` from the process CWD; the rspec process
      # runs from the engine root, so chdir to the dummy host (Rails.root)
      # where package.json lives.
      Dir.chdir(Rails.root) { Rake::Task["assets:precompile"].invoke }
    ensure
      $stdout.reopen(original_stdout)
      $stdout.puts "Finished in #{(Time.current - start).round(2)} seconds"
    end
  end

  config.after(:suite) do
    next unless needs_assets?
    next if dev_server_running?

    $stdout.puts "\n🗑️  Clobbering assets.\n"
    require "rake"
    Rails.application.load_tasks unless Rake::Task.task_defined?("assets:clobber")
    Rake::Task["assets:clobber"].invoke
  end
end
