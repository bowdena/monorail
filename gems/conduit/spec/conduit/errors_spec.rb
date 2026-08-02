RSpec.describe Conduit::Error do
  it "is a standard error" do
    expect(described_class.new("boom")).to be_a StandardError
  end

  it "carries the source it failed against" do
    error = described_class.new("boom", source: :ipm)

    expect(error.source).to eq :ipm
    expect(error.message).to eq "boom"
  end

  context "without a source" do
    it "has a nil source" do
      error = described_class.new("boom")

      expect(error.source).to be_nil
    end
  end

  describe "the taxonomy" do
    it "treats every failure mode as a Conduit::Error" do
      expect(described_class::NotConfigured.new("boom")).to be_a(described_class)
      expect(described_class::ConnectionFailed.new("boom")).to be_a(described_class)
      expect(described_class::Timeout.new("boom")).to be_a(described_class)
      expect(described_class::NotFound.new("boom")).to be_a(described_class)
      expect(described_class::QueryError.new("boom")).to be_a(described_class)
      expect(described_class::TooManyResults.new("boom"))
        .to be_a(described_class)
      expect(described_class::PermissionDenied.new("boom"))
        .to be_a(described_class)
      expect(described_class::AuthenticationFailed.new("boom"))
        .to be_a(described_class)
    end

    # The count is why the guard spends a COUNT(*) rather than probing
    # with a limit: a caller can say how much narrowing is needed.
    it "carries how many matched on TooManyResults" do
      error = described_class::TooManyResults.new(
        "2001 matches; narrow the search", source: :ipm, count: 2001
      )

      expect(error.count).to eq 2001
      expect(error.source).to eq :ipm
    end

    context "without a count" do
      it "has a nil count" do
        expect(described_class::TooManyResults.new("boom").count).to be_nil
      end
    end

    it "keeps source through subclasses" do
      error = described_class::ConnectionFailed.new(
        "login failed", source: :ipm
      )

      expect(error.source).to eq :ipm
    end
  end

  describe "#configuration?" do
    context "for NotConfigured, AuthenticationFailed, PermissionDenied" do
      it "is true" do
        expect(described_class::NotConfigured.new("x").configuration?).to be true
        expect(described_class::AuthenticationFailed.new("x").configuration?)
          .to be true
        expect(described_class::PermissionDenied.new("x").configuration?)
          .to be true
      end
    end

    context "for ConnectionFailed, QueryError, TooManyResults" do
      it "is false" do
        expect(described_class::ConnectionFailed.new("x").configuration?)
          .to be false
        expect(described_class::QueryError.new("x").configuration?).to be false
        expect(described_class::TooManyResults.new("x").configuration?)
          .to be false
      end
    end
  end

  describe "#transient?" do
    context "for ConnectionFailed and Timeout" do
      it "is true" do
        expect(described_class::ConnectionFailed.new("x").transient?).to be true
        expect(described_class::Timeout.new("x").transient?).to be true
      end
    end

    context "for NotConfigured, NotFound, QueryError, TooManyResults" do
      it "is false" do
        expect(described_class::NotConfigured.new("x").transient?).to be false
        expect(described_class::NotFound.new("x").transient?).to be false
        expect(described_class::QueryError.new("x").transient?).to be false
        expect(described_class::TooManyResults.new("x").transient?).to be false
      end
    end
  end
end
