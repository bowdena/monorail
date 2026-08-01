# Specs the container builder directly: Conduit.container went
# private in slice 5 (consuming apps reach data only through
# repositories), so the gem's own assertions build containers via
# Conduit::Container.build.
RSpec.describe Conduit::Container, :mssql do
  describe ".build" do
    it "builds a gateway per configured source" do
      container = described_class.build(Conduit.configuration)

      expect(container.gateways.keys).to eq %i[ipm]
    end

    it "skips sources that are not configured" do
      configuration = Conduit::Configuration.new
      configuration.application = "conduit_specs"

      container = described_class.build(configuration)

      expect(container.gateways.keys).to eq []
    end

    it "registers the ipm relations" do
      container = described_class.build(Conduit.configuration)

      expect(container.relations[:ipm_patients]).to be_a(ROM::Relation)
      expect(container.relations[:ipm_merged_patients])
        .to be_a(ROM::Relation)
      expect(container.relations[:ipm_reference_values])
        .to be_a(ROM::Relation)
    end
  end

  describe "ipm_patients relation" do
    it "reads active patients as domain-named tuples" do
      relation = described_class.build(Conduit.configuration)
        .relations[:ipm_patients]

      tuples = relation.active.to_a
      patient = tuples.find { |tuple| tuple[:urn] == "9025071" }
      expect(patient).to include(
        first_name: "Tori",
        last_name: "Judd",
        date_of_birth: Date.new(1957, 9, 29)
      )
      expect(patient[:patnt_refno]).to be_an(Integer)
      expect(patient).not_to have_key(:pasid)
    end

    it "excludes archived patients from active" do
      relation = described_class.build(Conduit.configuration)
        .relations[:ipm_patients]

      urns = relation.active.to_a.map { |tuple| tuple[:urn] }
      expect(urns).not_to include("0700004")
    end
  end

  describe "ipm_merged_patients relation" do
    it "reads merge links keyed by refno" do
      relation = described_class.build(Conduit.configuration)
        .relations[:ipm_merged_patients]

      links = relation.active.to_a
      expect(links).not_to be_empty
      expect(links.first[:patnt_refno]).to be_an(Integer)
      expect(links.first[:prev_patnt_refno]).to be_an(Integer)
    end
  end

  describe "ipm_reference_values relation" do
    it "reads reference domains" do
      relation = described_class.build(Conduit.configuration)
        .relations[:ipm_reference_values]

      genders = relation.to_a
        .select { |value| value[:rfvdm_code] == "GENDR" }
      expect(genders.map { |value| value[:description] })
        .to include("Female")
    end
  end
end
