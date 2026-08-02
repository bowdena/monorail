RSpec.describe Conduit::Page do
  describe ".of" do
    it "holds every record when unpaged" do
      page = described_class.of(%w[Ada Bea Cal])

      expect(page.records).to eq %w[Ada Bea Cal]
      expect(page.current_page).to eq 1
      expect(page.per_page).to be_nil
      expect(page.total_count).to eq 3
    end

    it "slices to the page asked for" do
      page = described_class.of(("a".."i").to_a, page: 2, per_page: 3)

      expect(page.records).to eq %w[d e f]
      expect(page.current_page).to eq 2
      expect(page.per_page).to eq 3
    end

    it "leaves the last page short" do
      page = described_class.of(("a".."g").to_a, page: 3, per_page: 3)

      expect(page.records).to eq %w[g]
    end

    it "counts the set, not the page" do
      page = described_class.of(("a".."g").to_a, page: 1, per_page: 3)

      expect(page.length).to eq 3
      expect(page.total_count).to eq 7
    end
  end

  describe "#total_pages" do
    context "when unpaged" do
      it "is a single page" do
        page = described_class.of(("a".."g").to_a)

        expect(page.total_pages).to eq 1
      end
    end

    context "when a page is partly filled" do
      it "rounds up" do
        page = described_class.of(("a".."g").to_a, per_page: 3)

        expect(page.total_pages).to eq 3
      end
    end

    context "when nothing matched" do
      it "is no pages at all" do
        page = described_class.of([], per_page: 3)

        expect(page.total_pages).to eq 0
      end
    end
  end

  describe "where the page sits" do
    context "when on the first of several pages" do
      it "has a next page only" do
        page = described_class.of(("a".."i").to_a, page: 1, per_page: 3)

        expect(page.first_page?).to be true
        expect(page.last_page?).to be false
        expect(page.next_page).to eq 2
        expect(page.previous_page).to be_nil
      end
    end

    context "when between the ends" do
      it "has both neighbours" do
        page = described_class.of(("a".."i").to_a, page: 2, per_page: 3)

        expect(page.first_page?).to be false
        expect(page.last_page?).to be false
        expect(page.next_page).to eq 3
        expect(page.previous_page).to eq 1
      end
    end

    context "when on the last of several pages" do
      it "has a previous page only" do
        page = described_class.of(("a".."i").to_a, page: 3, per_page: 3)

        expect(page.first_page?).to be false
        expect(page.last_page?).to be true
        expect(page.next_page).to be_nil
        expect(page.previous_page).to eq 2
      end
    end

    context "when unpaged" do
      it "is both first and last" do
        page = described_class.of(("a".."g").to_a)

        expect(page.first_page?).to be true
        expect(page.last_page?).to be true
        expect(page.next_page).to be_nil
        expect(page.previous_page).to be_nil
      end
    end

    context "when nothing matched" do
      it "is both first and last" do
        page = described_class.of([], per_page: 3)

        expect(page.first_page?).to be true
        expect(page.last_page?).to be true
        expect(page.next_page).to be_nil
        expect(page.previous_page).to be_nil
      end
    end
  end

  # Searches returned a bare Array before pages existed, so a page
  # has to stay usable everywhere one was.
  describe "enumeration" do
    it "iterates the page's own records" do
      page = described_class.of(("a".."i").to_a, page: 2, per_page: 3)

      expect(page.map(&:upcase)).to eq %w[D E F]
      expect(page.first).to eq "d"
      expect(page.to_a).to eq %w[d e f]
      expect(Array(page)).to eq %w[d e f]
    end

    it "sizes itself by the page" do
      page = described_class.of(("a".."g").to_a, page: 3, per_page: 3)

      expect(page.length).to eq 1
      expect(page.count).to eq 1
      expect(page.empty?).to be false
    end

    context "when nothing matched" do
      it "is empty" do
        page = described_class.of([])

        expect(page.empty?).to be true
        expect(page.length).to eq 0
        expect(page.to_a).to eq []
      end
    end
  end

  describe "invalid requests" do
    it "rejects a page below one" do
      expect { described_class.of(%w[Ada], page: 0) }
        .to raise_error(ArgumentError, /page must be at least 1/)
    end

    it "rejects a per_page below one" do
      expect { described_class.of(%w[Ada], per_page: 0) }
        .to raise_error(ArgumentError, /per_page must be at least 1/)
    end

    context "when the page is past the last" do
      it "names the page and the total" do
        expect { described_class.of(("a".."i").to_a, page: 5, per_page: 3) }
          .to raise_error(ArgumentError, "page 5 of 3")
      end
    end

    context "when nothing matched" do
      it "still allows page one" do
        page = described_class.of([], page: 1, per_page: 3)

        expect(page.records).to eq []
      end
    end
  end
end
