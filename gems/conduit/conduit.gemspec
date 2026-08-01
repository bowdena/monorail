require_relative "lib/conduit/version"

Gem::Specification.new do |spec|
  spec.name = "conduit"
  spec.version = Conduit::VERSION
  spec.authors = ["Andrew Bowden"]
  spec.email = ["andrew.bowden@minigeek.org"]
  spec.summary = "Read-only, multi-source data access over MSSQL."
  spec.description = "Conduit owns the shared MSSQL sources (locations, " \
                     "queries, failure handling) and gives consuming apps " \
                     "named read-only queries returning immutable records."
  # Internal NHS code — not licensed for redistribution, and never to be
  # pushed to a public gem host. The bogus allowed_push_host makes any
  # accidental `gem push` / `rake release` fail.
  spec.metadata["allowed_push_host"] = "https://gems.invalid"

  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "README.md"]
  end

  spec.add_dependency "activesupport", ">= 8.0"
  spec.add_dependency "rom", "~> 5.3"
  spec.add_dependency "rom-sql", "~> 3.6"
  spec.add_dependency "tiny_tds", "~> 3.0"
end
