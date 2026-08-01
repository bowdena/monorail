# Feature: Gesso-backed home page for clinical_exchange

## Goal
Give `clinical_exchange` a home page at `/` built from the gesso design
system, and steer future work at the gesso documentation before any new
markup is written.

## User Story
As a developer on clinical_exchange, I want the app to render a real page
through the shared design system, so that the gesso wiring is proven end to
end and every later page has a documented pattern to follow.

## Acceptance Criteria
- [ ] Visiting `/` returns a home page rather than the Rails welcome screen
- [ ] The page is visibly styled by the gesso theme — colour tokens,
      typography and component styles apply, not unstyled browser defaults
- [ ] The page is composed from existing gesso component helpers, with no
      hand-written copies of component markup
- [ ] Gesso's Stimulus behaviour loads in the browser on that page
- [ ] `bundle exec rspec` and `bin/rails lint` pass
- [ ] A developer editing a view or helper in this app is directed to the
      gesso documentation, in a defined order, before writing markup
- [ ] A developer who needs a component gesso lacks is directed to build it
      in the engine with a preview, a documentation page and a spec

## Implementation Notes

### Documentation lookup order (the rule being encoded)
1. `gems/gesso/spec/components/docs/06_for_llms/` — the agent-facing
   summary: build recipe, decision table, constraints, component helpers.
2. `gems/gesso/spec/components/docs/` — the human guidance in the same
   tree: `05_components/`, `04_patterns/`, `03_foundations/`,
   `02_principles`, `01_getting_started`.
3. `gems/gesso/spec/components/previews/` — the preview classes and their
   templates, which are the documented markup for partial-less components.

### Build precedence
- Compose from gesso first. Reach for basecoat (https://basecoatui.com/)
  only for something gesso does not cover, and prefer gesso's styling
  choices where the two differ.
- A new component — anything combining UI with behaviour, or UI tightly
  coupled to it — is built inside `gems/gesso`, never in the app. It ships
  as helper, partial, preview, documentation page, decision-table row and
  spec, per `06_for_llms/01_build_recipe.md.erb`.

### Wiring constraints found during intake
- Gesso needs `tailwindcss-rails`; its theme reaches a host through that
  gem's engine support at `app/assets/builds/tailwind/gesso`. The app
  currently uses `cssbundling-rails` with the `@tailwindcss/cli` npm
  package, so the pipeline is swapped before gesso is added.
- `gesso:install` writes the `build` script with `||=`, so it will not
  touch the app's existing esbuild script. That script must gain
  `--preserve-symlinks` by hand or the `link:`-installed `gesso` package
  will not resolve.
- The stale `cssbundling` output at `app/assets/builds/application.css`
  must be removed, or propshaft keeps serving it.
- `spec/dummy` in the gesso repo is the reference wiring; match it.
- Gesso's icons are vendored SVGs inside the engine, served through the
  `inline_svg` runtime dependency. No npm icon package is needed.
- The layout already uses `stylesheet_link_tag :app`, which is what the
  dummy host uses. No layout change is expected for CSS.

## Out of Scope
- Mounting Lookbook in `clinical_exchange`. Previews and docs are browsed
  through gesso's own dummy host.
- Building any new gesso component. The authoring rule ships as
  documentation and is exercised by a later feature that needs one.
- A second static page (`about`, and similar).
- Dark-mode theme toggle and the FOUC-prevention script in the layout.
- Authentication, navigation to other pages, and any database work.
- Adding an RSpec job to the GitHub Actions workflow.

## Open Questions
- `gems/gesso/README.md` points at `bin/lookbook` from the repo root, and
  at `apps/app_one` as a worked example. Neither exists. → Resolution: the
  new steering file documents the command that works today,
  `cd gems/gesso/spec/dummy && bin/dev`. Adding `bin/lookbook` and fixing
  the README are a separate chore.
- The GitHub Actions workflow runs only `scan_ruby` and `lint` — there is
  no RSpec job, so the system spec added here will not run in CI. → Flagged
  for a separate chore; `bin/ci` does run the suite locally.
- Exact locals for `render_header` and `render_card` are read from each
  partial's `locals: (...)` signature at implementation time, as the build
  recipe instructs. → Not a blocker.

## Slices

### Slice 1: Swap the CSS pipeline to tailwindcss-rails
**Commit:** `chore: build css with tailwindcss-rails`
**Files:**
- `apps/clinical_exchange/Gemfile`, `Gemfile.lock`
- `apps/clinical_exchange/package.json`, `yarn.lock`
- `apps/clinical_exchange/app/assets/tailwind/application.css` (new,
  replacing `app/assets/stylesheets/application.tailwind.css`)
- `apps/clinical_exchange/app/assets/builds/application.css` (removed)
- `apps/clinical_exchange/Procfile.dev`
**Spec:** No new spec. The existing suite and `bin/rails lint` must stay
green, and `bin/rails tailwindcss:build` must produce a stylesheet.
**Status:** pending

### Slice 2: Consume the gesso engine
**Commit:** `chore: consume the gesso design system`
**Files:**
- `apps/clinical_exchange/Gemfile`, `Gemfile.lock`
- `apps/clinical_exchange/package.json`, `yarn.lock`
- `apps/clinical_exchange/app/assets/tailwind/application.css`
- `apps/clinical_exchange/app/javascript/application.js`
- `apps/clinical_exchange/spec/support/precompile_assets.rb` (only if the
  generator adds one the app does not already have)
**Spec:** No new spec. Asset build succeeds and the gesso theme reaches
`app/assets/builds`.
**Status:** pending

### Slice 3: Home page at root
**Commit:** `feat: add a gesso-backed home page at root`
**Files:**
- `apps/clinical_exchange/app/controllers/static_pages_controller.rb`
- `apps/clinical_exchange/app/views/static_pages/home.html.erb`
- `apps/clinical_exchange/config/routes.rb`
- `apps/clinical_exchange/spec/requests/static_pages_spec.rb`
**Spec:** `GET /` responds 200, renders the `home` template, and the body
carries the markup the gesso helpers emit.
**Status:** pending

### Slice 4: Browser coverage for the home page
**Commit:** `test: cover the home page in a browser`
**Files:**
- `apps/clinical_exchange/spec/system/home_spec.rb`
**Spec:** Visiting `/` shows the heading, the gesso theme stylesheet is
served and applied, and gesso's Stimulus bundle is loaded — the check that
catches a silently empty asset build.
**Status:** pending

### Slice 5: Steer the app at the gesso documentation
**Commit:** `docs: steer llms to the gesso design system`
**Files:**
- `apps/clinical_exchange/.claude/rails/design_system.md` (new)
- `apps/clinical_exchange/CLAUDE.md` (self-loading table rows)
**Spec:** None — documentation.
**Status:** pending

### Slice 6: Component authoring rules inside gesso
**Commit:** `docs: add authoring rules to the gesso engine`
**Files:**
- `gems/gesso/CLAUDE.md` (new)
**Spec:** None — documentation.
**Status:** pending
