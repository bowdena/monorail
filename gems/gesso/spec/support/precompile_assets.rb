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
#
# This is the engine's own suite. The equivalent hook a consuming app gets
# is a separate file, installed unnamespaced as the app's own — see
# lib/generators/gesso/install/templates/precompile_assets.rb.
module Gesso
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
      # jsbundling runs `yarn build` from the process CWD; the rspec process
      # runs from the engine root, so chdir to the dummy host (Rails.root)
      # where package.json lives.
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
end

RSpec.configure do |config|
  config.before(:suite) do
    next unless Gesso::AssetPrecompilation.needed?

    if Gesso::AssetPrecompilation.dev_server_running?
      $stdout.puts "\n⚠️  Development server detected. Skipping asset precompilation.\n"
      next
    end

    $stdout.puts "\n🐢  Precompiling assets.\n"
    started_at = Time.current
    Gesso::AssetPrecompilation.quietly do
      Gesso::AssetPrecompilation.invoke("assets:precompile")
    end
    $stdout.puts "Finished in #{(Time.current - started_at).round(2)} seconds"
  end

  config.after(:suite) do
    next unless Gesso::AssetPrecompilation.needed?
    next if Gesso::AssetPrecompilation.dev_server_running?

    $stdout.puts "\n🗑️  Clobbering assets.\n"
    Gesso::AssetPrecompilation.invoke("assets:clobber")
  end
end
