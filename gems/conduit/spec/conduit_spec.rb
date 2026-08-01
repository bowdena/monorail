RSpec.describe Conduit do
  describe ".sources" do
    it "names the sources conduit can reach" do
      expect(described_class.sources).to eq %i[ipm]
    end
  end

  describe ".configure" do
    it "exposes application and sources" do
      described_class.reset!

      described_class.configure do |config|
        config.application = "app_one"
        config.source :ipm, username: "u", password: "p"
      end

      expect(described_class.configuration.application).to eq "app_one"
      expect(described_class.configuration.configured?(:ipm)).to be true
    end

    context "without an application name" do
      it "raises at configuration time" do
        described_class.reset!

        expect {
          described_class.configure do |config|
            config.source :ipm, username: "u", password: "p"
          end
        }.to raise_error(ArgumentError, /application/)
      end
    end
  end

  describe ".reset!" do
    it "clears the configuration" do
      described_class.configure do |config|
        config.application = "app_one"
      end

      described_class.reset!

      expect(described_class.configuration).to be_nil
    end
  end

  describe ".ipm" do
    context "when the ipm source is not configured" do
      it "raises NotConfigured without touching the database" do
        described_class.reset!

        expect { described_class.ipm }
          .to raise_error(Conduit::Error::NotConfigured) do |error|
            expect(error.source).to eq :ipm
            expect(error.configuration?).to be true
          end
      end
    end

    context "when the ipm source is configured" do
      it "hands out a memoized patients repository" do
        described_class.reset!
        described_class.configure do |config|
          config.application = "conduit_specs"
          config.source :ipm, username: "app", password: "secret"
        end

        repos = described_class.ipm

        expect(repos.patients)
          .to be_a(Conduit::IPM::Repositories::Patients)
        expect(repos.patients).to equal(repos.patients)

        described_class.reset!
      end
    end
  end
end
