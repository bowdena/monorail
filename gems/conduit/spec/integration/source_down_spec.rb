require "socket"

# The real unreachable-server error path — TCP refusal → TinyTDS →
# Sequel → conduit's error classification — with no test doubles.
# The unit specs (repository_spec) build driver errors by hand;
# this spec keeps them honest, and once is enough: the chain is
# identical for every source.
RSpec.describe "Source unavailability", :mssql do
  # "Down" is simulated by pointing the instance at a local port
  # nothing is listening on (via CONDUIT_MSSQL_PORT, re-read when
  # conduit is reconfigured). A refused connection exercises the
  # same error path as a stopped server, without the suite needing
  # control over the external instance it is given.
  around do |example|
    original_port = ENV["CONDUIT_MSSQL_PORT"]
    ENV["CONDUIT_MSSQL_PORT"] = closed_port.to_s
    # FreeTDS burns the whole login timeout on a refused connect,
    # once per rom-sql boot probe and once for the query; 1s keeps
    # these examples fast without faking any part of the chain.
    ENV["CONDUIT_LOGIN_TIMEOUT"] = "1"
    configure_conduit!

    example.run
  ensure
    ENV.delete("CONDUIT_LOGIN_TIMEOUT")
    if original_port
      ENV["CONDUIT_MSSQL_PORT"] = original_port
    else
      ENV.delete("CONDUIT_MSSQL_PORT")
    end
  end

  it "raises ConnectionFailed and records it in the audit trail" do
    events = []
    subscription = Conduit.on_query { |query| events << query }

    expect { Conduit.ipm.patients.by_urn("9025071") }
      .to raise_error(Conduit::Error::ConnectionFailed) do |error|
        expect(error.source).to eq :ipm
        expect(error.transient?).to be true
      end

    expect(events.length).to eq 1
    expect(events.first.error).to eq "Conduit::Error::ConnectionFailed"
    expect(events.first.row_count).to eq 0
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  # Regression: rom-repository's class-level relation cache once
  # pinned repositories to the first container they ever saw, so
  # recovery after reconfiguration is asserted, not assumed.
  context "when reconfigured back to a reachable instance" do
    it "recovers, rather than staying pinned to the down container" do
      expect { Conduit.ipm.patients.by_urn("9025071") }
        .to raise_error(Conduit::Error::ConnectionFailed)

      ENV.delete("CONDUIT_MSSQL_PORT")
      configure_conduit!

      expect(Conduit.ipm.patients.by_urn("9025071"))
        .to be_a(Conduit::IPM::Patient)
    end
  end

  # An ephemeral port that was free a moment ago: bind, note the
  # port, close. Connecting to it is then refused immediately, so no
  # waiting or retries are needed.
  def closed_port
    TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] }
  end
end
