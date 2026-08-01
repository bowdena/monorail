# Previews for the pagination component.
#
# Each scenario renders through render_pagination
# (Gesso::Components::PaginationHelper) via the shared pagination_preview/preview
# template.
#
# @label Pagination
class PaginationPreview < Lookbook::Preview
  # Usage rules: [Pagination design guidance](/lookbook/pages/components/pagination)
  def default
    preview(
      previous: { path: "?page=2" },
      next_page: { path: "?page=4" },
      pages: [
        { number: 1, path: "?page=1", current: false },
        :gap,
        { number: 3, path: "?page=3", current: true },
        { number: 4, path: "?page=4", current: false },
        { number: 5, path: "?page=5", current: false },
        :gap,
        { number: 10, path: "?page=10", current: false }
      ]
    )
  end

  # First page: no previous link, no leading ellipsis.
  def first_page
    preview(
      previous: nil,
      next_page: { path: "?page=2" },
      pages: [
        { number: 1, path: "?page=1", current: true },
        { number: 2, path: "?page=2", current: false },
        { number: 3, path: "?page=3", current: false },
        :gap,
        { number: 10, path: "?page=10", current: false }
      ]
    )
  end

  # Last page: no next link, no trailing ellipsis.
  def last_page
    preview(
      previous: { path: "?page=9" },
      next_page: nil,
      pages: [
        { number: 1, path: "?page=1", current: false },
        :gap,
        { number: 9, path: "?page=9", current: false },
        { number: 10, path: "?page=10", current: true }
      ]
    )
  end

  private
    def preview(pages: [], previous: nil, next_page: nil)
      render_with_template(template: "pagination_preview/preview",
        locals: { pages:, previous:, next_page: })
    end
end
