# A minimal stand-in for the reference_values relation: responds to
# #where(rfvdm_code:) and #to_a, and counts each load so the cache can
# be observed.
class FakeReferenceValues
  Result = Struct.new(:rows) do
    def to_a = rows
  end

  attr_reader :load_count

  def initialize(rows)
    @rows = rows
    @load_count = 0
  end

  def where(rfvdm_code:)
    @load_count += 1
    Result.new(@rows.select { |row| row[:rfvdm_code] == rfvdm_code })
  end
end

RSpec.describe Conduit::IPM::ReferenceLookup do
  subject(:lookup) { described_class.new(reference_values) }

  let(:rows) do
    [
      {rfvdm_code: "GENDR", rfval_refno: 1, description: "Female"},
      {rfvdm_code: "GENDR", rfval_refno: 2, description: "Male"},
      {rfvdm_code: "ETHGR", rfval_refno: 7, description: "Aboriginal"}
    ]
  end
  let(:reference_values) { FakeReferenceValues.new(rows) }

  describe "#description_for" do
    it "returns the description for a refno within a domain" do
      expect(lookup.description_for(1, "GENDR")).to eq "Female"
      expect(lookup.description_for(7, "ETHGR")).to eq "Aboriginal"
    end

    it "returns nil for an unknown refno" do
      expect(lookup.description_for(99, "GENDR")).to be_nil
    end

    it "keeps domains separate" do
      expect(lookup.description_for(1, "ETHGR")).to be_nil
      expect(lookup.description_for(1, "GENDR")).to eq "Female"
    end

    it "loads each domain once, then serves from cache" do
      lookup.description_for(1, "GENDR")
      lookup.description_for(2, "GENDR")
      lookup.description_for(7, "ETHGR")

      expect(reference_values.load_count).to eq 2
    end
  end
end
