RSpec.describe "UR search", :mssql do
  describe "Conduit.ipm.patients.by_urn" do
    it "returns the patient as a typed struct" do
      patient = Conduit.ipm.patients.by_urn("9025071")

      expect(patient).to be_a(Conduit::IPM::Patient)
      expect(patient.urn).to eq "9025071"
      expect(patient.first_name).to eq "Tori"
      expect(patient.last_name).to eq "Judd"
      expect(patient.date_of_birth).to eq Date.new(1957, 9, 29)
      expect(patient.gender).to eq "Female"
      expect(patient.atsi_status)
        .to eq "Neither Aboriginal nor Torres Strait Islander"
      expect(patient.merged_from).to be_nil
      expect(patient.merged?).to be false
    end

    context "when the URN was merged away" do
      it "returns the current record" do
        patient = Conduit.ipm.patients.by_urn("0700002")

        expect(patient.urn).to eq "0700003"
        expect(patient.last_name).to eq "Prior"
        expect(patient.merged_from).to eq "0700002"
        expect(patient.merged?).to be true
      end
    end

    context "when the merge chain has two hops" do
      it "resolves to the end of the chain" do
        patient = Conduit.ipm.patients.by_urn("0700001")

        expect(patient.urn).to eq "0700003"
        expect(patient.merged_from).to eq "0700001"
        expect(patient.atsi_status)
          .to eq "Aboriginal but not Torres Strait Islander"
      end
    end

    context "when the current record is searched" do
      it "returns it without merge metadata" do
        patient = Conduit.ipm.patients.by_urn("0700003")

        expect(patient.urn).to eq "0700003"
        expect(patient.merged_from).to be_nil
      end
    end

    context "when the patient is archived" do
      it "returns nil" do
        expect(Conduit.ipm.patients.by_urn("0700004")).to be_nil
      end
    end

    # Sam Holt 0700007 is active but merged into 0700008, whose
    # patient row is archived: the identity was merged away and its
    # successor retired, so no current record exists to return.
    context "when the merge chain ends at an archived patient" do
      it "returns nil" do
        expect(Conduit.ipm.patients.by_urn("0700007")).to be_nil
      end
    end

    # Patients 0700005 and 0700006 are deliberately corrupt
    # fixtures: each is recorded as merged into the other. The walk
    # must terminate at the far end of the loop rather than spin.
    context "when the merge data is cyclic" do
      it "terminates at the far end of the loop" do
        patient = Conduit.ipm.patients.by_urn("0700005")

        expect(patient.urn).to eq "0700006"
        expect(patient.merged_from).to eq "0700005"
      end
    end

    context "when no patient matches" do
      it "returns nil" do
        expect(Conduit.ipm.patients.by_urn("0000000")).to be_nil
      end
    end

    # Guards an assumption, not a behaviour — the patient returns
    # either way. That MERGE_MINOR_FLAG agrees with MERGED_PATIENTS
    # is sampled from production, not proven. The second example
    # keeps the first honest: a dead capture would satisfy it free.
    context "when the patient was never merged away" do
      it "skips MERGED_PATIENTS, on an assumption about the flag" do
        sql = capture_sql { Conduit.ipm.patients.by_urn("9025071") }

        expect(sql).to match(/FROM \[PATIENTS\]/i)
        expect(sql).not_to match(/MERGED_PATIENTS/i)
      end
    end

    context "when the patient was merged away" do
      it "reads MERGED_PATIENTS, as the flag says it must" do
        sql = capture_sql { Conduit.ipm.patients.by_urn("0700002") }

        expect(sql).to match(/MERGED_PATIENTS/i)
      end
    end
  end

  # Audit events fire per call, not per statement, so only Sequel's
  # own log distinguishes a skipped query from one that ran.
  def capture_sql
    buffer = StringIO.new
    logger = Logger.new(buffer)
    Sequel::DATABASES.each { |database| database.loggers << logger }

    yield

    buffer.string
  ensure
    Sequel::DATABASES.each { |database| database.loggers.delete(logger) }
  end

  describe "Conduit.ipm.patients.by_urn!" do
    it "returns the patient on a hit" do
      patient = Conduit.ipm.patients.by_urn!("9025071")

      expect(patient.urn).to eq "9025071"
    end

    context "when no patient matches" do
      it "raises NotFound naming the source" do
        expect { Conduit.ipm.patients.by_urn!("0000000") }
          .to raise_error(Conduit::Error::NotFound) do |error|
            expect(error.source).to eq :ipm
          end
      end
    end
  end
end
