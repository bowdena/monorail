require "rails_helper"
require "rails/generators"
require "generators/gesso/install/install_generator"

RSpec.describe Gesso::Generators::InstallGenerator do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def run_generator
    generator = described_class.new([], [], destination_root: @dir)
    generator.shell.mute { generator.invoke_all }
  end

  def read(relative)
    File.read(File.join(@dir, relative))
  end

  def write_package_json(contents)
    File.write(File.join(@dir, "package.json"), JSON.pretty_generate(contents))
  end

  it "writes the Tailwind entry importing gesso" do
    run_generator

    css = read("app/assets/tailwind/application.css")
    expect(css).to include('@import "tailwindcss"')
    expect(css).to include('@import "basecoat-css"')
    expect(css).to include('@import "../builds/tailwind/gesso"')
  end

  it "injects into an existing Tailwind entry without duplicating tailwindcss" do
    FileUtils.mkdir_p(File.join(@dir, "app/assets/tailwind"))
    File.write(File.join(@dir, "app/assets/tailwind/application.css"),
      %(@import "tailwindcss";\n))

    run_generator

    css = read("app/assets/tailwind/application.css")
    expect(css.scan('@import "tailwindcss"').size).to eq(1)
    expect(css).to include('@import "../builds/tailwind/gesso"')
  end

  it "imports gesso in the JS entry" do
    run_generator

    expect(read("app/javascript/application.js")).to include(%(import "gesso"\n))
  end

  it "adds the gesso package dependency and a preserve-symlinks build" do
    run_generator

    pkg = JSON.parse(read("package.json"))
    link = pkg.dig("dependencies", "gesso")
    expect(link).to start_with("link:")
    resolved = File.expand_path(link.delete_prefix("link:"), @dir)
    expect(resolved).to eq(Gesso::Engine.root.join("app/javascript").to_s)
    expect(pkg["dependencies"]).to include("basecoat-css")
    expect(pkg.dig("scripts", "build")).to include("--preserve-symlinks")
  end

  # The link:-installed gesso package only resolves when esbuild preserves
  # symlinks, so an app that already bundles has to gain the flag too.
  it "adds the flag to a build script that predates gesso" do
    write_package_json("scripts" => {
      "build" => "esbuild app/javascript/*.* --bundle --outdir=app/assets/builds"
    })

    run_generator

    build = JSON.parse(read("package.json")).dig("scripts", "build")
    expect(build).to include("--preserve-symlinks")
    expect(build).to include("--outdir=app/assets/builds")
  end

  it "does not add the flag twice" do
    write_package_json("scripts" => {
      "build" => "esbuild app/javascript/*.* --bundle --preserve-symlinks"
    })

    run_generator

    build = JSON.parse(read("package.json")).dig("scripts", "build")
    expect(build.scan("--preserve-symlinks").size).to eq(1)
  end

  # The flag is esbuild's. Appending it to some other bundler's command
  # would break a build the installer has no business rewriting.
  it "leaves a build script that does not use esbuild alone" do
    write_package_json("scripts" => { "build" => "rollup -c" })

    run_generator

    expect(JSON.parse(read("package.json")).dig("scripts", "build"))
      .to eq("rollup -c")
  end

  it "installs the asset precompile hook" do
    run_generator

    hook = read("spec/support/precompile_assets.rb")
    expect(hook).to include("assets:precompile")
    expect(hook).to include("module AssetPrecompilation")
  end

  # An app that already precompiles owns that setup — a second hook would
  # add a duplicate before(:suite) and leave it ambiguous which one runs.
  it "leaves an app that already precompiles alone" do
    FileUtils.mkdir_p(File.join(@dir, "spec/system/support"))
    File.write(File.join(@dir, "spec/system/support/precompile_assets.rb"),
      "# the app's own assets:precompile hook\n")

    run_generator

    expect(File.exist?(File.join(@dir, "spec/support/precompile_assets.rb")))
      .to be(false)
    expect(read("spec/system/support/precompile_assets.rb"))
      .to eq("# the app's own assets:precompile hook\n")
  end

  it "installs the foreman dev workflow" do
    run_generator

    expect(read("Procfile.dev")).to include("yarn build --watch")
    expect(read("Procfile.dev")).to include("tailwindcss:watch")
    expect(read("bin/dev")).to include("Procfile.dev")
    expect(File.executable?(File.join(@dir, "bin/dev"))).to be(true)
  end

  it "leaves a Procfile-based bin/dev alone" do
    FileUtils.mkdir_p(File.join(@dir, "bin"))
    File.write(File.join(@dir, "bin/dev"),
      "#!/usr/bin/env sh\nexec foreman start -f Procfile.dev -e .env\n")

    run_generator

    expect(read("bin/dev")).to include("-e .env")
  end
end
