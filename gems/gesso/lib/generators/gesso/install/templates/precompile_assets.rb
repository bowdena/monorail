# frozen_string_literal: true

# https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing

# Precompile assets before specs that render through the app (system specs,
# and request specs whose layout links the compiled CSS/JS), so the browser
# sees the gesso components styled and `bundle exec rspec` is green from a
# clean checkout with no manual build. assets:precompile is enhanced by
# tailwindcss-rails and jsbundling-rails, so it drives the real build
# pipeline. Skipped for helper-unit runs and when a dev server is running.
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
