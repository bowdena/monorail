require "json"
require "pathname"

module Gesso
  module Generators
    # Wires a host Rails app to consume the gesso design system: the
    # Tailwind entry, the Stimulus controllers import, and the JS package
    # dependencies. Run after adding `gem "gesso", path: ...` and
    # bundling:
    #
    #   bin/rails generate gesso:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Wire this app to consume the gesso design system."

      def add_tailwind_entry
        path = "app/assets/tailwind/application.css"
        if file_exists?(path)
          return if read(path).include?("builds/tailwind/gesso")

          inject_into_file path,
            %(@import "basecoat-css";\n@import "../builds/tailwind/gesso";\n),
            after: %r{@import "tailwindcss";\n}
        else
          template "application.css", path
        end
      end

      def add_javascript_import
        path = "app/javascript/application.js"
        create_file path, %(import "@hotwired/turbo-rails"\n) unless file_exists?(path)
        return if read(path).include?(%(import "gesso"\n))

        append_to_file path, %(import "gesso"\n)
      end

      def add_javascript_packages
        pkg = file_exists?("package.json") ? JSON.parse(read("package.json")) : {}

        (pkg["dependencies"] ||= {}).tap do |deps|
          deps["gesso"] ||= gesso_js_link
          deps["basecoat-css"] ||= "^0.3.11"
          deps["@hotwired/stimulus"] ||= "^3.2.2"
          deps["@hotwired/turbo-rails"] ||= "^8.0.23"
        end
        (pkg["devDependencies"] ||= {})["esbuild"] ||= "^0.28.1"
        (pkg["scripts"] ||= {})["build"] ||=
          "esbuild app/javascript/*.* --bundle --preserve-symlinks " \
          "--sourcemap --format=esm --outdir=app/assets/builds " \
          "--public-path=/assets"

        create_file "package.json", JSON.pretty_generate(pkg) + "\n", force: true
      end

      def add_precompile_hook
        return if file_exists?("spec/support/precompile_assets.rb")

        copy_file "precompile_assets.rb", "spec/support/precompile_assets.rb"
      end

      # Without watchers a fresh app boots unstyled: nothing populates
      # app/assets/builds. Ship the standard foreman workflow; replace
      # bin/dev only when it is not already Procfile-based (the stock
      # rails-new one just execs the server).
      def add_dev_workflow
        copy_file "Procfile.dev" unless file_exists?("Procfile.dev")

        unless file_exists?("bin/dev") && read("bin/dev").include?("Procfile.dev")
          copy_file "dev", "bin/dev", force: true
          chmod "bin/dev", 0755, verbose: false
        end
      end

      def show_post_install
        say ""
        say "gesso wired in. Remaining steps:", :green
        say %(  1. Ensure your Gemfile has: gem "gesso", path: "#{gesso_gem_path}")
        say "  2. Run: bundle install && yarn install"
        say "  3. Start bin/dev (or build once: bin/rails tailwindcss:build && yarn build)"
      end

      private
        def file_exists?(relative)
          File.exist?(File.join(destination_root, relative))
        end

        def read(relative)
          File.read(File.join(destination_root, relative))
        end

        # The generator only runs once bundler has loaded the engine, so
        # Gesso::Engine.root is the real on-disk gem location. Deriving
        # the paths from it keeps the install correct for apps at any
        # directory depth.
        def gesso_js_link
          engine_js = Gesso::Engine.root.join("app", "javascript")
          "link:#{engine_js.relative_path_from(destination_pathname)}"
        end

        def gesso_gem_path
          Gesso::Engine.root.relative_path_from(destination_pathname)
        end

        def destination_pathname
          Pathname.new(destination_root).expand_path
        end
    end
  end
end
