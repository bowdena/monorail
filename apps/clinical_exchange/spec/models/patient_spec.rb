require "rails_helper"

RSpec.describe Patient do
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

  it "keeps one record per urn" do
    create(:patient, urn: "0700003")

    expect { described_class.insert!({ urn: "0700003", last_name: "Judd" }) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
