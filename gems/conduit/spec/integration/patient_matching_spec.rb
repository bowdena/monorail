RSpec.describe "Patient matching", :mssql do
  describe "Conduit.ipm.patients.find_all_by" do
    it "matches names exactly, ignoring case" do
      patients = Conduit.ipm.patients.find_all_by(
        first_name: "TORI", last_name: "judd"
      )

      expect(patients.length).to eq 1
      expect(patients.first.urn).to eq "9025071"
      expect(patients.first.first_name).to eq "Tori"
    end

    it "combines criteria with AND" do
      patients = Conduit.ipm.patients.find_all_by(
        first_name: "Tori", last_name: "Boyd"
      )

      expect(patients).to eq []
    end

    # Ava Prior 0700001 and Pryor 0700002 share this date of birth
    # with Prior 0700003, having been merged into it.
    context "when merged-away records share the criteria" do
      it "returns only the current record" do
        patients = Conduit.ipm.patients.find_all_by(
          date_of_birth: Date.new(1962, 5, 14)
        )

        expect(patients.length).to eq 1
        expect(patients.first.urn).to eq "0700003"
        expect(patients.first.merged_from).to be_nil
      end
    end

    context "when the only match is a name the patient no longer has" do
      it "returns no records" do
        expect(Conduit.ipm.patients.find_all_by(last_name: "Pryor"))
          .to eq []
      end
    end

    context "when the only match is archived" do
      it "returns no records" do
        expect(Conduit.ipm.patients.find_all_by(last_name: "Vault"))
          .to eq []
      end
    end

    context "when every criterion is blank" do
      it "raises ArgumentError" do
        expect { Conduit.ipm.patients.find_all_by(last_name: "") }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe "Conduit.ipm.patients.matching" do
    it "matches partial names, ignoring case" do
      patients = Conduit.ipm.patients.matching(last_name: "uDD")

      expect(patients.length).to eq 1
      expect(patients.first.urn).to eq "9025071"
      expect(patients.first.last_name).to eq "Judd"
    end

    it "orders by surname then forename" do
      patients = Conduit.ipm.patients.matching(last_name: "e")

      expect(patients.map(&:last_name))
        .to eq %w[Case Dean Eden Lyle Reed]
    end

    it "identifies collection results by urn in the audit trail" do
      events = []
      subscription = Conduit.on_query { |query| events << query }

      patients = Conduit.ipm.patients.matching(last_name: "e")

      expect(events.length).to eq 1
      expect(events.first.name).to eq :matching
      expect(events.first.record_ids).to eq patients.map(&:urn)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end

    # Prior 0700001, Pryor 0700002 and Prior 0700003 all match, and
    # the first two were merged into the third.
    context "when merged-away rows match alongside the current row" do
      it "returns the current record alone" do
        patients = Conduit.ipm.patients.matching(last_name: "pr")

        expect(patients.length).to eq 1
        expect(patients.first.urn).to eq "0700003"
        expect(patients.first.merged_from).to be_nil
      end
    end

    # Ivy Knot is the only match and was merged away, so there is no
    # current record for the search to return.
    context "when every match is a merged-away record" do
      it "returns no records" do
        expect(Conduit.ipm.patients.matching(last_name: "kno"))
          .to eq []
      end
    end

    context "when the date of birth differs" do
      it "stays exact and excludes the patient" do
        patients = Conduit.ipm.patients.matching(
          last_name: "pr", date_of_birth: Date.new(1900, 1, 1)
        )

        expect(patients).to eq []
      end
    end

    context "when the only match is archived" do
      it "returns no records" do
        expect(Conduit.ipm.patients.matching(last_name: "vau"))
          .to eq []
      end
    end

    context "when the term contains LIKE wildcards" do
      it "treats them as literals" do
        expect(Conduit.ipm.patients.matching(last_name: "%"))
          .to eq []
      end
    end
  end

  # Every user value reaches SQL through Sequel's hash conditions
  # or predicate DSL, which quote literals — nothing is
  # interpolated. These examples are the tripwire: if a finder
  # ever regressed to string interpolation, the unbalanced quote
  # would raise a syntax error (QueryError) and the payload would
  # attempt a DROP (PermissionDenied) instead of returning cleanly.
  describe "SQL injection resistance" do
    it "treats a payload as a literal in every finder" do
      hostile = "'; DROP TABLE PATIENTS; --"

      expect(Conduit.ipm.patients.by_urn(hostile)).to be_nil
      expect(Conduit.ipm.patients.find_all_by(last_name: hostile))
        .to eq []
      expect(Conduit.ipm.patients.matching(last_name: hostile))
        .to eq []

      searched = Conduit.ipm.patients.by_urn("9025071")
      expect(searched.last_name).to eq "Judd"
    end

    it "handles a bare apostrophe in a name" do
      expect(Conduit.ipm.patients.matching(last_name: "O'Brien"))
        .to eq []
    end
  end
end
