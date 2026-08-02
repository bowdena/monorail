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

      expect(patients).to be_empty
    end

    context "when matches resolve to one patient" do
      it "returns the current record once" do
        patients = Conduit.ipm.patients.find_all_by(
          date_of_birth: Date.new(1962, 5, 14)
        )

        expect(patients.length).to eq 1
        expect(patients.first.urn).to eq "0700003"
        expect(patients.first.merged_from).to be_nil
      end
    end

    context "when a match is reachable only via merge" do
      it "carries the merged row's URN" do
        patients = Conduit.ipm.patients.find_all_by(last_name: "Pryor")

        expect(patients.length).to eq 1
        expect(patients.first.urn).to eq "0700003"
        expect(patients.first.merged_from).to eq "0700002"
      end
    end

    context "when the only match is archived" do
      it "returns no records" do
        expect(Conduit.ipm.patients.find_all_by(last_name: "Vault"))
          .to be_empty
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
      patients = Conduit.ipm.patients.matching(last_name: "PRY")

      expect(patients.length).to eq 1
      expect(patients.first.urn).to eq "0700003"
      expect(patients.first.merged_from).to eq "0700002"
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

    context "when merged rows match alongside the current row" do
      it "collapses them to the current record" do
        patients = Conduit.ipm.patients.matching(last_name: "pr")

        expect(patients.length).to eq 1
        expect(patients.first.urn).to eq "0700003"
        expect(patients.first.merged_from).to be_nil
      end
    end

    context "when the date of birth differs" do
      it "stays exact and excludes the patient" do
        patients = Conduit.ipm.patients.matching(
          last_name: "pr", date_of_birth: Date.new(1900, 1, 1)
        )

        expect(patients).to be_empty
      end
    end

    context "when the only match is archived" do
      it "returns no records" do
        expect(Conduit.ipm.patients.matching(last_name: "vau"))
          .to be_empty
      end
    end

    context "when the term contains LIKE wildcards" do
      it "treats them as literals" do
        expect(Conduit.ipm.patients.matching(last_name: "%"))
          .to be_empty
      end
    end
  end

  describe "the page a search returns" do
    it "holds every match as one page" do
      patients = Conduit.ipm.patients.matching(last_name: "e")

      expect(patients).to be_a Conduit::Page
      expect(patients.current_page).to eq 1
      expect(patients.per_page).to be_nil
      expect(patients.total_count).to eq 5
      expect(patients.total_pages).to eq 1
    end

    it "sits at both ends of one page" do
      patients = Conduit.ipm.patients.find_all_by(last_name: "Pryor")

      expect(patients).to be_a Conduit::Page
      expect(patients.first_page?).to be true
      expect(patients.last_page?).to be true
      expect(patients.next_page).to be_nil
      expect(patients.previous_page).to be_nil
    end

    # Searches answered with a bare Array before pages existed, and
    # consuming apps still treat them as collections.
    it "stays usable as a collection" do
      patients = Conduit.ipm.patients.matching(last_name: "e")

      expect(Array(patients).map(&:last_name))
        .to eq %w[Case Dean Eden Lyle Reed]
      expect(patients.length).to eq 5
      expect(patients.first.last_name).to eq "Case"
    end

    context "when nothing matched" do
      it "is an empty page" do
        patients = Conduit.ipm.patients.matching(last_name: "vau")

        expect(patients).to be_empty
        expect(patients.total_count).to eq 0
        expect(patients.total_pages).to eq 0
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
        .to be_empty
      expect(Conduit.ipm.patients.matching(last_name: hostile))
        .to be_empty

      searched = Conduit.ipm.patients.by_urn("9025071")
      expect(searched.last_name).to eq "Judd"
    end

    it "handles a bare apostrophe in a name" do
      expect(Conduit.ipm.patients.matching(last_name: "O'Brien"))
        .to be_empty
    end
  end
end
