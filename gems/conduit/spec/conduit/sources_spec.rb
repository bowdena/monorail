RSpec.describe Conduit::Sources do
  describe ".names" do
    it "lists the sources conduit owns" do
      expect(described_class.names).to eq %i[ipm]
    end
  end

  describe ".location" do
    it "returns local instance defaults in development" do
      location = described_class.location(env: {})

      expect(location).to eq(host: "localhost", port: 1433)
    end

    context "with conduit env overrides" do
      it "prefers the override values" do
        env = {
          "CONDUIT_MSSQL_HOST" => "db.internal",
          "CONDUIT_MSSQL_PORT" => "11433"
        }

        location = described_class.location(env: env)

        expect(location).to eq(host: "db.internal", port: 11433)
      end
    end
  end

  describe ".settings" do
    it "maps the ipm source to the production replica database" do
      settings = described_class.settings(:ipm, env: {})

      expect(settings).to eq(
        host: "localhost", port: 1433, database: "iPM_REPL"
      )
    end

    context "with conduit env overrides" do
      it "prefers the instance-level location" do
        env = {
          "CONDUIT_MSSQL_HOST" => "db.internal",
          "CONDUIT_MSSQL_PORT" => "11433"
        }

        settings = described_class.settings(:ipm, env: env)

        expect(settings[:host]).to eq "db.internal"
        expect(settings[:port]).to eq 11433
        expect(settings[:database]).to eq "iPM_REPL"
      end

      it "allows a database name per source" do
        env = {"CONDUIT_IPM_DATABASE" => "ipm_reporting"}

        settings = described_class.settings(:ipm, env: env)

        expect(settings[:database]).to eq "ipm_reporting"
      end
    end

    context "when in production without overrides" do
      it "fails naming the missing variable" do
        env = {"RAILS_ENV" => "production"}

        expect { described_class.settings(:ipm, env: env) }
          .to raise_error(
            Conduit::Error::NotConfigured, /CONDUIT_MSSQL_HOST/
          )
      end
    end

    context "when in production without a database name" do
      it "names the ipm variable for the ipm source" do
        env = {
          "RAILS_ENV" => "production",
          "CONDUIT_MSSQL_HOST" => "db.internal",
          "CONDUIT_MSSQL_PORT" => "1433"
        }

        expect { described_class.settings(:ipm, env: env) }
          .to raise_error(
            Conduit::Error::NotConfigured, /CONDUIT_IPM_DATABASE/
          )
      end
    end

    context "with an unknown source" do
      it "raises an argument error" do
        expect { described_class.settings(:pharmacy, env: {}) }
          .to raise_error(ArgumentError, /pharmacy/)
      end
    end
  end
end
