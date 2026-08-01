require "rails_helper"

# Unit spec for the toast view helper. render_toast maps Rails flash
# types to toast categories, roles, icons and an auto-dismiss duration,
# then renders the gesso/components/toast partial; here we call it directly and
# assert on the HTML it returns.
RSpec.describe Gesso::Components::ToastHelper, type: :helper do
  it "renders a success toast with role=status for a notice flash" do
    html = helper.render_toast(flash: { "notice" => "Your changes were saved." })
    page = Capybara.string(html)
    expect(page).to have_css(
      "#toaster .toast[data-category='success'][role='status']"
    )
    expect(page).to have_css(".toast p", text: "Your changes were saved.")
  end

  it "renders an error toast with role=alert for an alert flash" do
    html = helper.render_toast(flash: { "alert" => "Something went wrong." })
    expect(Capybara.string(html))
      .to have_css(".toast[data-category='error'][role='alert']")
  end

  it "maps an info flash to the info category" do
    html = helper.render_toast(flash: { "info" => "A new version is available." })
    expect(Capybara.string(html))
      .to have_css(".toast[data-category='info'][role='status']")
  end

  it "maps a warning flash to the warning category" do
    html = helper.render_toast(flash: { "warning" => "Session expiring." })
    expect(Capybara.string(html)).to have_css(".toast[data-category='warning']")
  end

  it "falls back to the info category for an unknown flash type" do
    html = helper.render_toast(flash: { "bizarre" => "Hmm." })
    expect(Capybara.string(html)).to have_css(".toast[data-category='info']")
  end

  it "renders one toast per flash message" do
    html = helper.render_toast(flash: { "notice" => "A", "warning" => "B" })
    expect(Capybara.string(html)).to have_css(".toast", count: 2)
  end

  it "renders a dismiss button for each toast" do
    html = helper.render_toast(flash: { "notice" => "Saved." })
    expect(Capybara.string(html))
      .to have_css(".toast footer button[aria-label='Dismiss']")
  end

  describe "auto-dismiss duration" do
    it "persists error toasts by default" do
      html = helper.render_toast(flash: { "alert" => "Failed." })
      expect(Capybara.string(html)).to have_css(".toast[data-duration='-1']")
    end

    it "auto-dismisses non-error toasts after 3s by default" do
      html = helper.render_toast(flash: { "notice" => "Saved." })
      expect(Capybara.string(html)).to have_css(".toast[data-duration='3000']")
    end

    it "gives error toasts a 5s window when auto_dismiss is true" do
      html = helper.render_toast(flash: { "alert" => "Failed." },
                                 auto_dismiss: true)
      expect(Capybara.string(html)).to have_css(".toast[data-duration='5000']")
    end

    it "persists every toast when auto_dismiss is false" do
      html = helper.render_toast(flash: { "notice" => "Saved." },
                                 auto_dismiss: false)
      expect(Capybara.string(html)).to have_css(".toast[data-duration='-1']")
    end
  end

  it "renders nothing when the flash is empty" do
    html = helper.render_toast(flash: {})
    expect(html.to_s.strip).to be_empty
  end
end
