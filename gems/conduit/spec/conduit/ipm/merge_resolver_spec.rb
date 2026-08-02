RSpec.describe Conduit::IPM::MergeResolver do
  describe "#resolve" do
    it "returns a nil pair for a nil row" do
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      resolver = described_class.new(patients, merged_patients)

      expect(resolver.resolve(nil)).to eq [nil, nil]
    end

    it "returns a direct hit unchanged" do
      smith = {patnt_refno: 3, urn: "0700003",
               first_name: "Sam", last_name: "Smith"}
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      allow(merged_patients).to receive(:latest_targets).and_return({})
      resolver = described_class.new(patients, merged_patients)

      expect(resolver.resolve(smith)).to eq [smith, nil]
    end

    it "follows a merge, carrying the searched urn" do
      pryor = {patnt_refno: 2, urn: "0700002",
               first_name: "Pat", last_name: "Pryor"}
      smith = {patnt_refno: 3, urn: "0700003",
               first_name: "Sam", last_name: "Smith"}
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      allow(merged_patients).to receive(:latest_targets) do |refnos|
        {2 => 3}.slice(*refnos)
      end
      allow(patients).to receive(:active_by_refnos) do |refnos|
        {3 => smith}.slice(*refnos)
      end
      resolver = described_class.new(patients, merged_patients)

      expect(resolver.resolve(pryor)).to eq [smith, "0700002"]
    end

    context "when the chain runs more than one hop" do
      it "resolves to the last record" do
        pryor = {patnt_refno: 2, urn: "0700002",
                 first_name: "Pat", last_name: "Pryor"}
        smith = {patnt_refno: 4, urn: "0700004",
                 first_name: "Sam", last_name: "Smith"}
        patients = instance_double(Conduit::IPM::Relations::Patients)
        merged_patients =
          instance_double(Conduit::IPM::Relations::MergedPatients)
        allow(merged_patients).to receive(:latest_targets) do |refnos|
          {2 => 3, 3 => 4}.slice(*refnos)
        end
        allow(patients).to receive(:active_by_refnos) do |refnos|
          {4 => smith}.slice(*refnos)
        end
        resolver = described_class.new(patients, merged_patients)

        expect(resolver.resolve(pryor)).to eq [smith, "0700002"]
      end
    end

    context "when the chain is cyclic" do
      it "stops instead of looping forever" do
        pryor = {patnt_refno: 2, urn: "0700002",
                 first_name: "Pat", last_name: "Pryor"}
        smith = {patnt_refno: 3, urn: "0700003",
                 first_name: "Sam", last_name: "Smith"}
        patients = instance_double(Conduit::IPM::Relations::Patients)
        merged_patients =
          instance_double(Conduit::IPM::Relations::MergedPatients)
        allow(merged_patients).to receive(:latest_targets) do |refnos|
          {2 => 3, 3 => 2}.slice(*refnos)
        end
        allow(patients).to receive(:active_by_refnos) do |refnos|
          {3 => smith}.slice(*refnos)
        end
        resolver = described_class.new(patients, merged_patients)

        expect(resolver.resolve(pryor)).to eq [smith, "0700002"]
      end
    end

    context "when the current record is archived" do
      it "drops the match" do
        vault = {patnt_refno: 5, urn: "0700005", last_name: "Vault"}
        patients = instance_double(Conduit::IPM::Relations::Patients)
        merged_patients =
          instance_double(Conduit::IPM::Relations::MergedPatients)
        allow(merged_patients).to receive(:latest_targets) do |refnos|
          {5 => 6}.slice(*refnos)
        end
        allow(patients).to receive(:active_by_refnos).and_return({})
        resolver = described_class.new(patients, merged_patients)

        expect(resolver.resolve(vault)).to eq [nil, nil]
      end
    end
  end

  describe "#resolve_all" do
    it "drops rows that do not resolve" do
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      resolver = described_class.new(patients, merged_patients)

      expect(resolver.resolve_all([])).to eq []
    end

    it "collapses rows for one patient" do
      pryor = {patnt_refno: 2, urn: "0700002",
               first_name: "Pat", last_name: "Pryor"}
      smith = {patnt_refno: 3, urn: "0700003",
               first_name: "Sam", last_name: "Smith"}
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      allow(merged_patients).to receive(:latest_targets) do |refnos|
        {2 => 3}.slice(*refnos)
      end
      allow(patients).to receive(:active_by_refnos) do |refnos|
        {3 => smith}.slice(*refnos)
      end
      resolver = described_class.new(patients, merged_patients)

      resolutions = resolver.resolve_all([pryor, smith])

      expect(resolutions.length).to eq 1
      tuple, merged_from = resolutions.first
      expect(tuple).to eq smith
      expect(merged_from).to be_nil
    end

    it "orders by surname then forename" do
      smith = {patnt_refno: 3, urn: "0700003",
               first_name: "Sam", last_name: "Smith"}
      dean = {patnt_refno: 4, urn: "0700004",
              first_name: "Bea", last_name: "Dean"}
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      allow(merged_patients).to receive(:latest_targets).and_return({})
      resolver = described_class.new(patients, merged_patients)

      resolutions = resolver.resolve_all([smith, dean])

      expect(resolutions.map { |tuple, _| tuple[:last_name] })
        .to eq %w[Dean Smith]
    end
  end

  # The cost of resolution must track how deep merge chains run, not
  # how many rows matched. A query per row would put a ceiling on how
  # large a searchable result set can be.
  describe "the queries it issues" do
    it "asks once for a whole set of rows" do
      rows = (1..50).map do |refno|
        {patnt_refno: refno, urn: format("07%05d", refno),
         first_name: "Ann", last_name: format("Nash%02d", refno)}
      end
      patients = instance_double(Conduit::IPM::Relations::Patients)
      merged_patients =
        instance_double(Conduit::IPM::Relations::MergedPatients)
      allow(merged_patients).to receive(:latest_targets).and_return({})
      resolver = described_class.new(patients, merged_patients)

      resolutions = resolver.resolve_all(rows)

      expect(resolutions.length).to eq 50
      expect(merged_patients).to have_received(:latest_targets).once
    end

    context "when no row was merged" do
      it "never loads current records" do
        rows = (1..50).map do |refno|
          {patnt_refno: refno, urn: format("07%05d", refno),
           first_name: "Ann", last_name: format("Nash%02d", refno)}
        end
        patients = instance_double(Conduit::IPM::Relations::Patients)
        merged_patients =
          instance_double(Conduit::IPM::Relations::MergedPatients)
        allow(merged_patients).to receive(:latest_targets).and_return({})
        allow(patients).to receive(:active_by_refnos).and_return({})
        resolver = described_class.new(patients, merged_patients)

        resolver.resolve_all(rows)

        expect(patients).not_to have_received(:active_by_refnos)
      end
    end

    context "when rows merge one hop" do
      it "loads every current record at once" do
        rows = (1..50).map do |refno|
          {patnt_refno: refno, urn: format("07%05d", refno),
           first_name: "Ann", last_name: format("Nash%02d", refno)}
        end
        current = (1..50).to_h do |refno|
          resolved = {patnt_refno: refno + 100,
                      urn: format("08%05d", refno),
                      first_name: "Bea",
                      last_name: format("Vale%02d", refno)}
          [refno + 100, resolved]
        end
        patients = instance_double(Conduit::IPM::Relations::Patients)
        merged_patients =
          instance_double(Conduit::IPM::Relations::MergedPatients)
        allow(merged_patients).to receive(:latest_targets) do |refnos|
          (1..50).to_h { |refno| [refno, refno + 100] }.slice(*refnos)
        end
        allow(patients).to receive(:active_by_refnos) do |refnos|
          current.slice(*refnos)
        end
        resolver = described_class.new(patients, merged_patients)

        resolutions = resolver.resolve_all(rows)

        expect(resolutions.length).to eq 50
        expect(merged_patients).to have_received(:latest_targets).twice
        expect(patients).to have_received(:active_by_refnos).once
      end
    end

    context "when an empty set is resolved" do
      it "issues no queries at all" do
        patients = instance_double(Conduit::IPM::Relations::Patients)
        merged_patients =
          instance_double(Conduit::IPM::Relations::MergedPatients)
        allow(merged_patients).to receive(:latest_targets).and_return({})
        allow(patients).to receive(:active_by_refnos).and_return({})
        resolver = described_class.new(patients, merged_patients)

        resolver.resolve_all([])

        expect(merged_patients).not_to have_received(:latest_targets)
        expect(patients).not_to have_received(:active_by_refnos)
      end
    end
  end
end
