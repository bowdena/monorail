
# One page of a patient search, and where that page sits in the whole
# result set.
#
# The page maths is stated again here rather than borrowed from
# Conduit::Page: only the iPM path has one of those, and the local
# fallback counts and slices in SQL instead of handing over every row it
# matched.
Patient::Results = Data.define(
  :records, :source, :current_page, :per_page, :total_count
) do
  def local?
    source == :local
  end

  def total_pages
    return 0 if total_count.zero?
    return 1 if per_page.nil?

    (total_count.to_f / per_page).ceil
  end

  def first_page?
    current_page == 1
  end

  def last_page?
    current_page >= total_pages
  end

  def next_page
    last_page? ? nil : current_page + 1
  end

  def previous_page
    first_page? ? nil : current_page - 1
  end
end
