RSpec.describe "Query audit events", :mssql do
  it "describes a successful query without row data" do
    events = []
    subscription = Conduit.on_query { |query| events << query }

    Conduit.ipm.patients.by_urn("9025071")

    expect(events.length).to eq 1
    event = events.first
    expect(event.application).to eq "conduit_specs"
    expect(event.source).to eq :ipm
    expect(event.resource).to eq "ipm_patients"
    expect(event.name).to eq :by_urn
    expect(event.params).to eq(urn: "9025071")
    expect(event.duration).to be > 0
    expect(event.row_count).to eq 1
    expect(event.record_ids).to eq ["9025071"]
    expect(event.error).to be_nil
    expect(event.to_h.values.join).not_to include("Judd")
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  # Merge resolution runs several statements inside one named query;
  # the trail records the query, not its statements, and identifies
  # the row that was actually returned.
  it "emits one event for a merge-resolved query" do
    events = []
    subscription = Conduit.on_query { |query| events << query }

    Conduit.ipm.patients.by_urn("0700001")

    expect(events.length).to eq 1
    expect(events.first.params).to eq(urn: "0700001")
    expect(events.first.record_ids).to eq ["0700003"]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end
end
