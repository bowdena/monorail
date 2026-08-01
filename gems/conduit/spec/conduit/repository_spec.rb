# Drives the audit/error base through a probe repository's public
# finder: manufactured driver errors go in, classified
# Conduit::Error subclasses and query.conduit events come out.
# TinyTds::Error exposes writable db_error_number/severity, so real
# driver exceptions are built rather than stubbed;
# Sequel::DatabaseError offers no writer for wrapped_exception, so
# the one wrapped-path example sets the ivar it publicly reads.
class ProbeRepo < Conduit::Repository[:ipm_patients]
  def probe(failure = nil, result: "a-record")
    one(:probe, {probing: true}) do
      raise failure if failure
      result
    end
  end

  private

  def source = :ipm
  def resource_name = "probe"
  def record_identifier(record) = record
end

RSpec.describe Conduit::Repository do
  def probe_repo
    Conduit.reset!
    Conduit.configure do |config|
      config.application = "conduit_specs"
      config.source :ipm, username: "app", password: "secret"
    end
    ProbeRepo.new(Conduit.send(:container))
  end

  def tinytds_error(message, number: nil)
    error = TinyTds::Error.new(message)
    error.db_error_number = number
    error
  end

  describe "error classification by MSSQL error number" do
    it "classifies login failures" do
      failure = tinytds_error("Login failed", number: 18456)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::AuthenticationFailed) do |error|
          expect(error.source).to eq :ipm
          expect(error.configuration?).to be true
          expect(error.cause).to be failure
        end
    end

    it "classifies missing databases as permission denied" do
      failure = tinytds_error("Database 'X' does not exist", number: 911)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::PermissionDenied)
    end

    it "classifies databases that can't be opened as permission denied" do
      failure = tinytds_error("Cannot open database \"X\"", number: 4060)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::PermissionDenied)
    end

    it "classifies denied selects" do
      failure = tinytds_error("SELECT permission was denied", number: 229)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::PermissionDenied)
    end

    it "classifies denied column access as permission denied" do
      failure = tinytds_error(
        "SELECT permission was denied on the column 'ssn'", number: 230
      )

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::PermissionDenied)
    end

    it "classifies statement timeouts" do
      failure = tinytds_error("connection timed out", number: 20003)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::Timeout) do |error|
          expect(error.transient?).to be true
        end
    end

    it "classifies unreachable servers" do
      failure = tinytds_error("Unable to connect", number: 20009)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::ConnectionFailed) do |error|
          expect(error.transient?).to be true
        end
    end

    it "classifies dead connections as connection failed" do
      failure = tinytds_error("Connection is dead", number: 20047)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::ConnectionFailed) do |error|
          expect(error.transient?).to be true
        end
    end

    it "reads the number through Sequel's wrapper" do
      driver = tinytds_error("connection timed out", number: 20003)
      wrapped = Sequel::DatabaseError.new("TinyTds::Error: timed out")
      wrapped.instance_variable_set(:@wrapped_exception, driver)

      expect { probe_repo.probe(wrapped) }
        .to raise_error(Conduit::Error::Timeout)
    end
  end

  describe "fallback classification" do
    it "matches an authentication failure by message alone" do
      failure = tinytds_error("Login failed for user 'app'")

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::AuthenticationFailed)
    end

    it "matches a connection failure by message alone" do
      failure = tinytds_error("Adaptive Server is unavailable")

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::ConnectionFailed)
    end

    it "matches a permission denial by message alone" do
      failure = tinytds_error("Cannot open database requested by the login")

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::PermissionDenied)
    end

    it "defaults statement errors to QueryError" do
      failure = tinytds_error("Incorrect syntax near 'FROM'", number: 102)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::QueryError)
    end

    it "defaults connection-stage errors to ConnectionFailed" do
      failure = Sequel::DatabaseConnectionError.new("socket closed")

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::ConnectionFailed)
    end

    it "lets non-database errors propagate untranslated" do
      expect { probe_repo.probe(NoMethodError.new("gem bug")) }
        .to raise_error(NoMethodError, "gem bug")
    end
  end

  describe "audit events" do
    it "describes a successful query" do
      events = []
      subscription = Conduit.on_query { |query| events << query }

      probe_repo.probe

      expect(events.length).to eq 1
      event = events.first
      expect(event.application).to eq "conduit_specs"
      expect(event.source).to eq :ipm
      expect(event.resource).to eq "probe"
      expect(event.name).to eq :probe
      expect(event.params).to eq(probing: true)
      expect(event.row_count).to eq 1
      expect(event.record_ids).to eq ["a-record"]
      expect(event.error).to be_nil
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    it "records nothing found as zero rows" do
      events = []
      subscription = Conduit.on_query { |query| events << query }

      expect(probe_repo.probe(nil, result: nil)).to be_nil

      expect(events.first.row_count).to eq 0
      expect(events.first.record_ids).to eq []
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    it "records the classified error class on failure" do
      events = []
      subscription = Conduit.on_query { |query| events << query }
      failure = tinytds_error("Login failed", number: 18456)

      expect { probe_repo.probe(failure) }
        .to raise_error(Conduit::Error::AuthenticationFailed)

      expect(events.length).to eq 1
      expect(events.first.error)
        .to eq "Conduit::Error::AuthenticationFailed"
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end
  end
end
