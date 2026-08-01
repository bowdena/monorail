Patient::Results = Data.define(:records, :source) do
  def local?
    source == :local
  end
end
