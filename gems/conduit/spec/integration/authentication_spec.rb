RSpec.describe "Authentication against a live server", :mssql do
  it "raises AuthenticationFailed for a wrong password" do
    Conduit.reset!
    Conduit.configure do |config|
      config.application = "conduit_specs"
      config.source :ipm, username: "conduit_app_one",
        password: "Wrong_password1"
    end

    expect { Conduit.ipm.patients.by_urn("9025071") }
      .to raise_error(Conduit::Error::AuthenticationFailed) do |error|
        expect(error.source).to eq :ipm
        expect(error.configuration?).to be true
      end
  end
end
