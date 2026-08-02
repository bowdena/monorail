require "rails_helper"

# Tailwind's preflight makes every svg display:block, so an icon inside a
# button will push its label onto a second line unless the button lays its
# content out as a flex row. Only a browser can catch that, so the layout
# is measured rather than asserted on the markup.
RSpec.describe "Button component", type: :system do
  it "keeps an icon and its label on one line" do
    visit "/lookbook/preview/button/with_icon"

    boxes = evaluate_script(<<~JS)
      (() => {
        const button = document.querySelector("button.btn");
        const icon = button.querySelector("svg").getBoundingClientRect();
        const range = document.createRange();
        range.selectNodeContents(
          [...button.querySelectorAll("*"), button]
            .flatMap((element) => [...element.childNodes])
            .find((node) => node.nodeType === Node.TEXT_NODE &&
                            node.textContent.trim() === "Search")
        );
        const label = range.getBoundingClientRect();
        return { icon: icon, label: label,
                 height: button.getBoundingClientRect().height };
      })()
    JS

    icon = boxes["icon"]
    label = boxes["label"]

    icon_centre = icon["top"] + (icon["height"] / 2)
    label_centre = label["top"] + (label["height"] / 2)

    expect(label["left"]).to be >= icon["right"]
    expect(label_centre).to be_within(1).of(icon_centre)
  end

  it "submits the form it belongs to" do
    visit "/lookbook/preview/button/in_a_form"

    click_button "Save"

    expect(page).to have_current_path(/submitted=yes/, url: true)
  end
end
