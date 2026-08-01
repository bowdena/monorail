module Gesso::Components
  module ThemeToggleHelper
    # Renders the theme toggle — an icon button that cycles the colour
    # theme (system → light → dark) via its Stimulus `theme` controller,
    # which swaps the visible icon to match and persists the choice. No
    # params. This atomic component is inlined here; it has no partial.
    #
    #   render_theme_toggle
    def render_theme_toggle
      button_tag(type: "button", name: nil, class: "btn",
        aria: { label: "Toggle theme" },
        data: { controller: "theme", action: "click->theme#cycle",
                variant: "ghost", size: "icon" }) do
        safe_join([
          tag.span(inline_svg_tag("icons/sun.svg", size: "16"),
            data: { theme_target: "sun" }, class: "hidden"),
          tag.span(inline_svg_tag("icons/moon.svg", size: "16"),
            data: { theme_target: "moon" }, class: "hidden"),
          tag.span(inline_svg_tag("icons/monitor.svg", size: "16"),
            data: { theme_target: "monitor" })
        ])
      end
    end
  end
end
