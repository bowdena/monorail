# Gesso

Gesso is the shared design system for this monorepo — a mountable Rails
engine packaging the basecoat/shadcn component helpers, the Tailwind
theme, and the Stimulus behaviour that give every app a consistent look
and feel.

It ships three things to a host app:

- **Component helpers** — `render_alert`, `render_card`, `render_header`,
  `render_sidebar`, … (mixed into ActionView automatically) and their
  partials.
- **Tailwind theme + component styles** — the clinical colour tokens and
  per-component CSS, via tailwindcss-rails engine support.
- **Stimulus controllers** — shipped as the `gesso` npm package
  (`app/javascript`) and bundled by the host with esbuild.

## Consuming gesso in an app

Because gesso lives in the same repository as the apps, a single PR can
change a component and the app that uses it together — there is no
separate library to publish or version.

1. Add the engine to the app's `Gemfile` and bundle:

   ```ruby
   gem "gesso", path: "../../gems/gesso"
   ```

   ```sh
   bundle install
   ```

2. Run the installer to wire assets and JavaScript:

   ```sh
   bin/rails generate gesso:install
   ```

   This writes the Tailwind entry (`app/assets/tailwind/application.css`),
   adds `import "gesso"` to `app/javascript/application.js`,
   adds the `gesso`, `basecoat-css`, Stimulus, and Turbo packages
   (plus a `--preserve-symlinks` esbuild build script) to `package.json`,
   installs the asset precompile hook for browser specs, and ships the
   foreman `Procfile.dev` + `bin/dev` dev workflow.

3. Install JS deps and start the app:

   ```sh
   yarn install
   bin/dev   # web + js watch + css watch; builds assets on start
   ```

4. Render components and use the shared theme:

   ```erb
   <%= render_card(title: "Welcome") do %>
     <p class="text-warning">Anything can use the shared tokens.</p>
   <% end %>
   ```

`apps/app_one` is a worked example of all of the above.

## Adding or changing a component

All reusable components live in this engine — the single source of truth.
Add or edit the helper (`app/helpers/gesso/components`), the partial
(`app/views/gesso/components`), any component CSS (`app/assets/tailwind`),
and a spec, then preview it in Lookbook. Markup-only components with no
partial (badge, skeleton, table, …) still get a preview class + template
under `spec/components/previews` — the template is their documented
markup, and the design docs embed it live. Apps pick the change up
automatically because they consume the engine at HEAD.

## Development

The engine is exercised through a dummy host at `spec/dummy` — a full
Rails app consuming gesso like any other, with demo pages and Lookbook
mounted at `/lookbook`.

```sh
bundle exec rspec        # component + system specs; assets precompile
bundle exec rake lint    # automatically via the before(:suite) hook

cd spec/dummy && bin/dev # demo pages at :3000, Lookbook at :3000/lookbook
```

(From the repo root, `bin/lookbook` is a shortcut for that last line.)
