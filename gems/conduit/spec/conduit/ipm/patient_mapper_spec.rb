RSpec.describe Conduit::IPM::PatientMapper do
  subject(:mapper) { described_class.new(reference_lookup) }

  let(:reference_lookup) do
    instance_double(Conduit::IPM::ReferenceLookup)
  end
  let(:tuple) do
    {
      urn: "0700003",
      first_name: "Tori",
      last_name: "Judd",
      date_of_birth: Date.new(1962, 5, 14),
      gendr_refno: 2,
      ethgr_refno: 7
    }
  end

  before do
    allow(reference_lookup).to receive(:description_for)
      .with(2, "GENDR").and_return("Male")
    allow(reference_lookup).to receive(:description_for)
      .with(7, "ETHGR").and_return("Aboriginal")
  end

  describe "#call" do
    it "maps a tuple to a Patient, resolving coded values" do
      patient = mapper.call(tuple, merged_from: nil)

      expect(patient).to have_attributes(
        urn: "0700003",
        first_name: "Tori",
        last_name: "Judd",
        date_of_birth: Date.new(1962, 5, 14),
        gender: "Male",
        atsi_status: "Aboriginal",
        merged_from: nil
      )
    end

    it "carries the merge origin through" do
      patient = mapper.call(tuple, merged_from: "0700002")

      expect(patient.merged_from).to eq "0700002"
      expect(patient).to be_merged
    end

    it "leaves an unresolved coded value nil" do
      allow(reference_lookup).to receive(:description_for)
        .with(2, "GENDR").and_return(nil)

      expect(mapper.call(tuple, merged_from: nil).gender).to be_nil
    end
  end

  describe "#call_all" do
    it "maps each [tuple, merged_from] resolution" do
      patients = mapper.call_all([[tuple, "0700002"], [tuple, nil]])

      expect(patients.map(&:merged_from)).to eq ["0700002", nil]
      expect(patients.map(&:urn)).to eq %w[0700003 0700003]
    end
  end
end
