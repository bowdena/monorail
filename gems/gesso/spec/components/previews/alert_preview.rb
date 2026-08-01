# Previews for the alert component.
#
# Each scenario renders through render_alert (Gesso::Components::AlertHelper)
# via the shared alert_preview/preview template.
#
# @label Alert
class AlertPreview < Lookbook::Preview
  # Usage rules: [Alert design guidance](/lookbook/pages/components/alert)
  #
  # @param variant select [default, destructive, warning, critical, info]
  # @param icon text
  # @param title text
  # @param body text
  def playground(variant: "default", icon: "icons/info",
                 title: "Heads up", body: "This is an alert message.")
    preview(variant:, icon:, title:, body:)
  end

  # Every variant rendered together — embedded in the design docs.
  def variants
    render_with_template(template: "alert_preview/variants")
  end

  def default
    preview(title: "Heads up", body: "Something you should know about.")
  end

  def destructive
    preview(variant: "destructive", icon: "icons/alert-circle",
            title: "Error", body: "Something went wrong.")
  end

  def with_icon
    preview(icon: "icons/info", title: "Note",
            body: "An alert with a leading icon.")
  end

  def warning
    preview(variant: "warning", icon: "icons/alert-triangle",
            title: "Warning", body: "Proceed with caution.")
  end

  def critical
    preview(variant: "critical", icon: "icons/shield-alert",
            title: "Critical", body: "Immediate attention required.")
  end

  def info
    preview(variant: "info", icon: "icons/info",
            title: "Information", body: "For your information.")
  end

  private
    def preview(variant: "default", icon: nil, title: nil, body: nil)
      render_with_template(template: "alert_preview/preview",
        locals: { variant:, icon:, title:, body: })
    end
end
