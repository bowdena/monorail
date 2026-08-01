module Gesso::Components
  module PaginationHelper
    # Renders the pagination component. This is the public entry point;
    # pagination is purely structural, so the helper passes the handed-in
    # window straight to the partial. The caller computes which numbers
    # and gaps to show — this helper does no page maths.
    #
    #   render_pagination(pages:, previous:, next_page:)
    def render_pagination(pages: [], previous: nil, next_page: nil)
      render("gesso/components/pagination",
        pages:, previous:, next_page:)
    end
  end
end
