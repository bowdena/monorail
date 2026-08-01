require "rails_helper"
require "json"

RSpec.describe "The gesso npm package" do
  let(:package) do
    JSON.parse(Gesso::Engine.root.join("app/javascript/package.json").read)
  end

  it "exports the Stimulus application for host apps to register on" do
    expect(package["exports"])
      .to include("./application" => "./controllers/application.js")
  end

  # The module's side effect is Application.start(). Without this entry a
  # bundler is free to drop it when a host imports only the binding.
  it "marks the application module as having side effects" do
    expect(package["sideEffects"]).to include("./controllers/application.js")
  end
end
