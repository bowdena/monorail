# Design System Guidelines

This application does not own its user interface components. They live in
the `gesso` engine at `gems/gesso`, a mountable Rails engine consumed at
HEAD — a single commit can change a component and the page using it.

Read this before writing any markup in `app/views` or `app/helpers`.

## Where the answers live

Work down this list. Stop at the first level that answers the question.

1. **`gems/gesso/spec/components/docs/06_for_llms/`** — written for
   agents, and the fastest route to a correct answer.
   - `01_build_recipe.md.erb` — the steps for composing a page and for
     adding a component
   - `02_decision_table.md.erb` — need → partial → key locals, plus the
     frequent tie-breaks
   - `03_constraints.md.erb` — the never/always rules; a build that
     breaks one of these is wrong even if it renders
   - `04_component_helpers.md.erb` — the helper/partial/preview/spec
     pattern
2. **The rest of `gems/gesso/spec/components/docs/`** — the human
   guidance the summary above compresses. `05_components/` has a page per
   component, `04_patterns/` covers forms, feedback, overlays and
   navigation, `03_foundations/` covers colour, typography, spacing,
   icons and content, and `02_principles.md.erb` explains the reasoning.
3. **`gems/gesso/spec/components/previews/`** — the preview classes and
   their templates. For components with no partial (badge, skeleton,
   table, separator, …) the preview template *is* the documented markup.

The partial itself is the final authority on what it accepts. Every one
declares a strict `locals: (...)` signature on its first line followed by
a doc comment describing each param. Read that before rendering it.

## Composing a page

Component helpers are mixed into ActionView automatically — the engine is
deliberately not namespace-isolated, so `render_card`, `render_header`,
`render_alert` and the rest are available in this app's views with no
`include` and no prefix.

- Render through the helper, not the partial: `render_card(title: "…")`.
- Pass locals by name and take the defaults unless there is a reason not
  to. Do not pass a param no current page needs.
- Lay out with container utilities — cards in `grid gap-4`, page regions
  `p-6`. Never put margins on a component.
- Use colour tokens by meaning (`bg-warning`, `text-critical`), never a
  hard-coded colour or an inline `style` attribute.
- Report the outcome of an action through flash and the toast component;
  report the state of the page with `alert`.

## Choosing what to build with

1. **Gesso first.** If the decision table names a partial for the need,
   use it. Never hand-write markup a partial already covers.
2. **Basecoat second.** Gesso is built on basecoat, so basecoat's classes
   and patterns (https://basecoatui.com/) are the source for anything
   gesso has not styled yet.
3. **Where the two differ, gesso wins.** Its theme tokens and component
   styles are the house style; basecoat is the substrate.

## When gesso has no component for it

Start inline, in the page that needs it. Most UI never needs to be a
component, and a partial that only maps a variant onto a class string is
worse than the class.

Promote it into `gems/gesso` — never into this app — when a third page
needs the same thing, or immediately when it bundles behaviour, state or
an accessibility contract a caller could get wrong. Anything combining
markup with behaviour belongs in the engine.

Building it there means a helper, a partial, a Lookbook preview, a
guidance page, a row in the decision table, and specs. `gems/gesso/CLAUDE.md`
covers that work; do not start it from this file.

## Seeing the components

Lookbook is mounted by the engine's own dummy host, not by this app:

```sh
cd gems/gesso/spec/dummy && bin/dev   # previews and docs at :3000/lookbook
```

The gesso README refers to a `bin/lookbook` shortcut at the repository
root. It does not exist — use the command above.

## Stimulus

Gesso starts the page's single Stimulus application. This app's
`app/javascript/controllers/application.js` re-exports that instance
rather than calling `Application.start()` again, so `bin/rails generate
stimulus` and `stimulus:manifest:update` work normally and every
controller registers on the one application. Do not start a second one.
