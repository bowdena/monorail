module Gesso
  # Non-isolated engine: the component partials live on the host view path
  # and the Gesso::Components::*Helper modules are shared with host controllers'
  # views automatically (isolate_namespace is what would switch that off),
  # so host apps can call render_alert, render_card, … with no boilerplate.
  class Engine < ::Rails::Engine
    # Use the bare "gesso" name (not the derived "gesso_engine") so the
    # tailwindcss-rails engine entry is app/assets/tailwind/gesso/engine.css
    # and consumers import "../builds/tailwind/gesso".
    engine_name "gesso"

    # Point Lookbook at the engine's previews and design docs. The host app
    # mounts Lookbook; the previews and docs ship with the engine. Must run
    # before lookbook.set_autoload_paths: that is where Lookbook copies
    # preview_paths into the autoload paths that load the preview classes.
    initializer "gesso.lookbook", before: "lookbook.set_autoload_paths" do |app|
      if defined?(::Lookbook)
        app.config.lookbook.preview_paths <<
          root.join("spec/components/previews").to_s
        app.config.lookbook.page_paths <<
          root.join("spec/components/docs").to_s

        # Theme dropdown in the preview inspector and embeds; the host's
        # preview layout applies params.dig(:lookbook, :display, :theme).
        # Guarded so a host that sets its own :theme options wins.
        display = app.config.lookbook.preview_display_options || {}
        display[:theme] ||= %w[ light dark ]
        app.config.lookbook.preview_display_options = display
      end
    end
  end
end
