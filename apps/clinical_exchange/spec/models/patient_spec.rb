require "rails_helper"

RSpec.describe Patient do
  # Conduit is stubbed at its public boundary: the app suite never reaches
  # MSSQL, and the gem's own specs cover the SQL.
  def stub_ipm(patients)
    allow(Conduit).to receive(:ipm)
      .and_return(instance_double(Conduit::IPM::Repos, patients: patients))
  end

  def ipm_patient(urn: "0700003", first_name: "Tori", last_name: "Judd")
    Conduit::IPM::Patient.new(
      urn: urn, first_name: first_name, last_name: last_name,
      date_of_birth: Date.new(1957, 9, 29), gender: "Female",
      atsi_status: nil, merged_from: nil
    )
  end

  # The id reaches the browser as a URL, so it must not be guessable and
  # must not be the URN.
  it "is keyed by a uuid the database generates" do
    patient = create(:patient)

    expect(patient.id).to match(
      /\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
    )
    expect(described_class.new.id).to be_nil
  end

  # Rails would default a uuid key to gen_random_uuid(), which is version
  # 4, so the migration names uuidv7() itself.
  it "takes its uuid from uuidv7" do
    id = described_class.columns.find { |column| column.name == "id" }

    expect(id.default_function).to eq("uuidv7()")
  end

  describe ".remember" do
    it "keeps the patient conduit returned" do
      found = Conduit::IPM::Patient.new(
        urn: "0700003", first_name: "Tori", last_name: "Judd",
        date_of_birth: Date.new(1957, 9, 29), gender: "Female",
        atsi_status: "Neither", merged_from: nil
      )

      patient = described_class.remember(found)

      expect(patient).to be_persisted
      expect(patient.urn).to eq("0700003")
      expect(patient.first_name).to eq("Tori")
      expect(patient.last_name).to eq("Judd")
      expect(patient.date_of_birth).to eq(Date.new(1957, 9, 29))
      expect(patient.gender).to eq("Female")
      expect(patient.atsi_status).to eq("Neither")
    end

    it "keeps the urn a merge resolved from" do
      merged = Conduit::IPM::Patient.new(
        urn: "0700003", first_name: "Tori", last_name: "Judd",
        date_of_birth: Date.new(1957, 9, 29), gender: "Female",
        atsi_status: nil, merged_from: "0400009"
      )

      expect(described_class.remember(merged).merged_from).to eq("0400009")
    end

    context "when the patient is already known" do
      it "refreshes the record rather than adding another" do
        create(:patient, urn: "0700003", last_name: "Judd")
        renamed = Conduit::IPM::Patient.new(
          urn: "0700003", first_name: "Tori", last_name: "Judd-Smith",
          date_of_birth: Date.new(1957, 9, 29), gender: "Female",
          atsi_status: nil, merged_from: nil
        )

        expect { described_class.remember(renamed) }
          .not_to change(described_class, :count)

        expect(described_class.sole.last_name).to eq("Judd-Smith")
      end
    end
  end

  describe ".by_urn" do
    it "finds the patient with that urn" do
      create(:patient, urn: "0700003", last_name: "Judd")
      create(:patient, urn: "0400009", last_name: "Nolan")

      expect(described_class.by_urn("0700003").last_name).to eq("Judd")
    end

    it "matches the urn exactly" do
      create(:patient, urn: "0700003")

      expect(described_class.by_urn("700003")).to be_nil
    end
  end

  describe ".matching" do
    it "matches a name fragment, whatever the case" do
      create(:patient, first_name: "Tori", last_name: "Judd")
      create(:patient, first_name: "Alan", last_name: "Nolan")

      expect(described_class.matching(last_name: "jud").pluck(:last_name))
        .to eq([ "Judd" ])
    end

    it "matches a first name fragment" do
      create(:patient, first_name: "Tori", last_name: "Judd")
      create(:patient, first_name: "Alan", last_name: "Nolan")

      expect(described_class.matching(first_name: "or").pluck(:first_name))
        .to eq([ "Tori" ])
    end

    it "matches a date of birth exactly" do
      create(:patient, last_name: "Judd", date_of_birth: Date.new(1957, 9, 29))
      create(:patient, last_name: "Nolan", date_of_birth: Date.new(1961, 4, 2))

      found = described_class.matching(date_of_birth: Date.new(1957, 9, 29))

      expect(found.pluck(:last_name)).to eq([ "Judd" ])
    end

    it "narrows on every criterion given" do
      create(:patient, first_name: "Tori", last_name: "Judd",
        date_of_birth: Date.new(1957, 9, 29))
      create(:patient, first_name: "Tori", last_name: "Judd",
        date_of_birth: Date.new(1980, 1, 1))

      found = described_class.matching(
        first_name: "Tori", last_name: "Judd",
        date_of_birth: Date.new(1957, 9, 29)
      )

      expect(found.pluck(:date_of_birth)).to eq([ Date.new(1957, 9, 29) ])
    end

    it "finds nobody when nothing matches" do
      create(:patient, last_name: "Judd")

      expect(described_class.matching(last_name: "Nolan")).to be_empty
    end

    it "treats a wildcard as a literal" do
      create(:patient, last_name: "Judd")

      expect(described_class.matching(last_name: "%")).to be_empty
    end

    context "when every criterion is blank" do
      it "raises rather than matching the whole table" do
        create(:patient, last_name: "Judd")

        expect { described_class.matching(first_name: " ", last_name: nil) }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe ".search" do
    it "answers from iPM, and says so" do
      patients = instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient)
      stub_ipm(patients)

      results = described_class.search(urn: "0700003")

      expect(results.records.map(&:urn)).to eq([ "0700003" ])
      expect(results.source).to eq(:ipm)
      expect(results).not_to be_local
    end

    it "pads a short urn to seven digits" do
      patients = instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: ipm_patient)
      stub_ipm(patients)

      described_class.search(urn: "700003")

      expect(patients).to have_received(:by_urn).with("0700003")
    end

    it "finds nobody when iPM has no such urn" do
      stub_ipm(instance_double(Conduit::IPM::Repositories::Patients,
        by_urn: nil))

      results = described_class.search(urn: "0700003")

      expect(results.records).to be_empty
      expect(results.source).to eq(:ipm)
    end

    it "asks iPM to match the name criteria given" do
      patients = instance_double(Conduit::IPM::Repositories::Patients,
        matching: [ ipm_patient ])
      stub_ipm(patients)

      described_class.search(last_name: "jud",
        date_of_birth: Date.new(1957, 9, 29))

      expect(patients).to have_received(:matching).with(
        first_name: nil, last_name: "jud",
        date_of_birth: Date.new(1957, 9, 29)
      )
    end

    context "when iPM is unreachable" do
      it "answers from local records instead" do
        create(:patient, urn: "0700003", last_name: "Judd")
        patients = instance_double(Conduit::IPM::Repositories::Patients)
        allow(patients).to receive(:by_urn).and_raise(
          Conduit::Error::ConnectionFailed.new("down", source: :ipm)
        )
        stub_ipm(patients)

        results = described_class.search(urn: "0700003")

        expect(results.records.map(&:urn)).to eq([ "0700003" ])
        expect(results).to be_local
      end

      it "matches names against local records" do
        create(:patient, last_name: "Judd")
        patients = instance_double(Conduit::IPM::Repositories::Patients)
        allow(patients).to receive(:matching).and_raise(
          Conduit::Error::Timeout.new("slow", source: :ipm)
        )
        stub_ipm(patients)

        results = described_class.search(last_name: "jud")

        expect(results.records.map(&:last_name)).to eq([ "Judd" ])
        expect(results).to be_local
      end
    end

    context "when iPM is misconfigured" do
      it "raises rather than answering from local records" do
        create(:patient, urn: "0700003")
        patients = instance_double(Conduit::IPM::Repositories::Patients)
        allow(patients).to receive(:by_urn).and_raise(
          Conduit::Error::PermissionDenied.new("no grant", source: :ipm)
        )
        stub_ipm(patients)

        expect { described_class.search(urn: "0700003") }
          .to raise_error(Conduit::Error::PermissionDenied)
      end
    end

    context "when the query itself fails" do
      it "raises rather than answering from local records" do
        patients = instance_double(Conduit::IPM::Repositories::Patients)
        allow(patients).to receive(:matching).and_raise(
          Conduit::Error::QueryError.new("bad sql", source: :ipm)
        )
        stub_ipm(patients)

        expect { described_class.search(last_name: "jud") }
          .to raise_error(Conduit::Error::QueryError)
      end
    end

    context "when every criterion is blank" do
      it "raises without asking iPM" do
        patients = instance_double(Conduit::IPM::Repositories::Patients)
        stub_ipm(patients)

        expect { described_class.search(urn: " ", last_name: nil) }
          .to raise_error(ArgumentError)
      end
    end
  end

  it "keeps one record per urn" do
    create(:patient, urn: "0700003")

    expect { described_class.insert!({ urn: "0700003", last_name: "Judd" }) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
