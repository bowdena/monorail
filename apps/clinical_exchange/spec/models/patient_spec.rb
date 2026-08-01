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

  it "keeps one record per urn" do
    create(:patient, urn: "0700003")

    expect { described_class.insert!({ urn: "0700003", last_name: "Judd" }) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
