require "rails_helper"

RSpec.describe Patient::Results do
  def results(records: [], source: :ipm, current_page: 1, per_page: nil,
    total_count: nil)
    described_class.new(records: records, source: source,
      current_page: current_page, per_page: per_page,
      total_count: total_count || records.length)
  end

  describe "#local?" do
    it "is true only for locally kept records" do
      expect(results(source: :local)).to be_local
      expect(results(source: :ipm)).not_to be_local
    end
  end

  describe "#total_pages" do
    context "when unpaged" do
      it "is a single page" do
        expect(results(records: %w[ a b c ]).total_pages).to eq(1)
      end
    end

    context "when a page is partly filled" do
      it "rounds up" do
        found = results(records: %w[ a b c ], per_page: 25,
          total_count: 60)

        expect(found.total_pages).to eq(3)
      end
    end

    context "when nothing matched" do
      it "is no pages at all" do
        expect(results(per_page: 25).total_pages).to eq(0)
      end
    end
  end

  describe "where the page sits" do
    context "when on the first of several pages" do
      it "has a next page only" do
        found = results(records: %w[ a ], current_page: 1, per_page: 25,
          total_count: 60)

        expect(found.first_page?).to be(true)
        expect(found.last_page?).to be(false)
        expect(found.next_page).to eq(2)
        expect(found.previous_page).to be_nil
      end
    end

    context "when between the ends" do
      it "has both neighbours" do
        found = results(records: %w[ a ], current_page: 2, per_page: 25,
          total_count: 60)

        expect(found.next_page).to eq(3)
        expect(found.previous_page).to eq(1)
      end
    end

    context "when on the last of several pages" do
      it "has a previous page only" do
        found = results(records: %w[ a ], current_page: 3, per_page: 25,
          total_count: 60)

        expect(found.last_page?).to be(true)
        expect(found.next_page).to be_nil
        expect(found.previous_page).to eq(2)
      end
    end

    context "when nothing matched" do
      it "is both first and last" do
        found = results(per_page: 25)

        expect(found.first_page?).to be(true)
        expect(found.last_page?).to be(true)
        expect(found.next_page).to be_nil
        expect(found.previous_page).to be_nil
      end
    end
  end
end
