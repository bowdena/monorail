require_relative "lib/gesso/version"

Gem::Specification.new do |spec|
  spec.name        = "gesso"
  spec.version     = Gesso::VERSION
  spec.authors     = [ "Andrew Bowden" ]
  spec.email       = [ "andrew.bowden@minigeek.org" ]
  spec.summary     = "Shared design system (shadcn + basecoat) as a Rails engine."
  spec.description = "Gesso packages the basecoat/shadcn component helpers, " \
                     "Tailwind theme, and Stimulus behaviour as a mountable " \
                     "Rails engine for the apps in this monorepo to consume."
  # Internal NHS code — not licensed for redistribution, and never to be
  # pushed to a public gem host. The bogus allowed_push_host makes any
  # accidental `gem push` / `rake release` fail.
  spec.metadata["allowed_push_host"] = "https://gems.invalid"

  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    # The previews and docs ship too: the engine initializer points
    # Lookbook at them, so a built gem must contain them.
    Dir["{app,config,lib,tasks}/**/*",
        "spec/components/{previews,docs}/**/*",
        "Rakefile", "README.md"]
  end

  # The engine only touches the framework via railties (engine, generators,
  # rake tasks) and actionview (helpers, partials) — not the full rails
  # meta-gem.
  spec.add_dependency "railties", ">= 8.1"
  spec.add_dependency "actionview", ">= 8.1"
  spec.add_dependency "inline_svg"
end
