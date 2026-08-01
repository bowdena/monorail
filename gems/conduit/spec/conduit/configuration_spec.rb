RSpec.describe Conduit::Configuration do
  describe "#source" do
    it "registers credentials for a known source" do
      config = described_class.new
      config.application = "app_one"

      config.source :ipm, username: "conduit_app_one",
        password: "sandbox"

      expect(config.configured?(:ipm)).to be true
      expect(config.configured?(:pharmacy)).to be false
    end

    context "with an unknown source" do
      it "raises at configuration time, naming the known sources" do
        config = described_class.new

        expect { config.source :pharmacy, username: "u", password: "p" }
          .to raise_error(
            ArgumentError,
            "Unknown conduit source: pharmacy. Known sources: ipm"
          )
      end
    end

    context "with blank credentials" do
      it "raises naming the missing part" do
        config = described_class.new

        expect { config.source :ipm, username: nil, password: "p" }
          .to raise_error(ArgumentError, /username/)
        expect { config.source :ipm, username: "u", password: "" }
          .to raise_error(ArgumentError, /password/)
      end
    end
  end

  describe "#credentials_for" do
    it "returns the source credentials" do
      config = described_class.new
      config.application = "app_one"
      config.source :ipm, username: "conduit_app_one",
        password: "sandbox_secret"

      credentials = config.credentials_for(:ipm)

      expect(credentials.username).to eq "conduit_app_one"
      expect(credentials.password).to eq "sandbox_secret"
    end

    context "when the source is not configured" do
      it "returns nil" do
        config = described_class.new

        expect(config.credentials_for(:ipm)).to be_nil
      end
    end
  end
end
