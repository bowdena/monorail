# Previews for the table.
#
# A table is a semantic <table> styled by basecoat's `table` class,
# written inline (no partial or helper); the scenario renders the
# documented markup so the design docs can embed a live example.
#
# @label Table
class TablePreview < Lookbook::Preview
  # Usage rules: [Table design guidance](/lookbook/pages/components/table)
  def default
    render_with_template(template: "table_preview/default")
  end
end
