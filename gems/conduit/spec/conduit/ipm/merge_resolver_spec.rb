RSpec.describe Conduit::IPM::MergeResolver do
  subject(:resolver) { described_class.new(patients, merged_patients) }

  let(:patients) { instance_double(Conduit::IPM::Relations::Patients) }
  let(:merged_patients) do
    instance_double(Conduit::IPM::Relations::MergedPatients)
  end

  let(:pryor) do
    {patnt_refno: 2, urn: "0700002", first_name: "Pat", last_name: "Pryor"}
  end
  let(:smith) do
    {patnt_refno: 3, urn: "0700003", first_name: "Sam", last_name: "Smith"}
  end

  # Wires the merge graph: each pair says "prev refno was merged into
  # target refno". Unlisted refnos have no target (chain ends).
  def merges(graph)
    allow(merged_patients).to receive(:latest_target) do |refno|
      graph[refno]
    end
  end

  describe "#resolve" do
    it "returns a nil pair for a nil row" do
      expect(resolver.resolve(nil)).to eq [nil, nil]
    end

    it "returns a direct hit unchanged, with no merge origin" do
      merges({})

      expect(resolver.resolve(smith)).to eq [smith, nil]
    end

    it "follows a merge to the current row, carrying the searched urn" do
      merges(2 => 3)
      allow(patients).to receive(:active_by_refno).with(3).and_return(smith)

      expect(resolver.resolve(pryor)).to eq [smith, "0700002"]
    end

    it "stops on a cyclic chain instead of looping forever" do
      merges(2 => 3, 3 => 2)
      allow(patients).to receive(:active_by_refno).with(3).and_return(smith)

      expect(resolver.resolve(pryor)).to eq [smith, "0700002"]
    end

    it "drops a match whose current record is archived" do
      merges(5 => 6)
      allow(patients).to receive(:active_by_refno).with(6).and_return(nil)
      vault = {patnt_refno: 5, urn: "0700005", last_name: "Vault"}

      expect(resolver.resolve(vault)).to eq [nil, nil]
    end
  end

  describe "#resolve_all" do
    it "collapses rows for one patient, direct hit winning" do
      merges(2 => 3)
      allow(patients).to receive(:active_by_refno).with(3).and_return(smith)

      resolutions = resolver.resolve_all([pryor, smith])

      expect(resolutions.length).to eq 1
      tuple, merged_from = resolutions.first
      expect(tuple).to eq smith
      expect(merged_from).to be_nil
    end

    it "orders distinct patients by surname then forename" do
      merges({})
      dean = {patnt_refno: 4, urn: "0700004",
              first_name: "Bea", last_name: "Dean"}

      resolutions = resolver.resolve_all([smith, dean])

      expect(resolutions.map { |tuple, _| tuple[:last_name] })
        .to eq %w[Dean Smith]
    end

    it "drops rows that do not resolve" do
      expect(resolver.resolve_all([])).to eq []
    end
  end
end
