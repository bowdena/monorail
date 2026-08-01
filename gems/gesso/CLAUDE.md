# Gesso — Claude Guidelines

Gesso is the shared design system for this monorepo: a mountable Rails
engine packaging the component helpers, the Tailwind theme, and the
Stimulus behaviour that give every app the same look and feel.

Apps in `apps/` consume it at HEAD, so one commit can change a component
and the page that uses it. There is no release step, and no version to
bump — which also means a careless change here breaks a running app in
the same commit.

Your personal `~/.claude/CLAUDE.md` still applies. Where it conflicts
with this file on how the engine is built, this file wins.

## The engine documents itself

`spec/components/docs/06_for_llms/` is binding for component work. Read
it before changing anything under `app/`:

- `03_constraints.md.erb` — the never/always rules. A change that breaks
  one of these is wrong even if it renders correctly.
- `01_build_recipe.md.erb` — the steps for composing a page and adding a
  component.
- `04_component_helpers.md.erb` — the helper/partial/preview pattern,
  with `button` as the reference implementation.
- `02_decision_table.md.erb` — need → partial → key locals.

Consuming apps are pointed at the same documents by
`apps/clinical_exchange/.claude/rails/design_system.md`.

## Adding or changing a component

A component is markup, styling and behaviour together. Something that
only maps a variant onto a class string is not a component — the class is
the API, and the markup belongs inline in the page that needs it.

Nothing ships as a component without its preview, its guidance page and
its specs. Those are not follow-up work: they land in the same commit.

1. Write the spec first — `spec/components/<name>_spec.rb`, rendering the
   Lookbook preview and asserting the DOM.
2. Helper — `app/helpers/gesso/components/<name>_helper.rb`, defining
   `render_<name>`. The helper owns allowed values as frozen constants,
   raises `ArgumentError` naming them for an unknown option, composes
   classes with `class_names`, and builds markup with Rails tag helpers.
   Render the partial with the string-plus-block form; the
   `partial:`/`locals:` form does not pass the block to `yield`.
3. Partial — `app/views/gesso/components/_<name>.html.erb`. Pure markup,
   opening with a strict `locals: (...)` signature and a doc comment
   describing each param. Accept `classes`, yield a block for content.
4. Styling — basecoat's shipped classes first. Only if basecoat has no
   styling for it, add `app/assets/tailwind/components/<name>.css` and
   import it from `app/assets/tailwind/gesso/engine.css`.
5. Preview — `spec/components/previews/<name>_preview.rb` and its
   template directory, with a scenario per variant. For a component with
   no partial, the preview template *is* the documented markup.
6. Docs — a guidance page at `spec/components/docs/05_components/
   <name>.md.erb` and a row in the decision table. A component the
   decision table does not mention will not be found.
7. Run `bundle exec rspec` and then `bundle exec rake lint`. Both pass
   before the work is done, in that order.

## Where specs live

| What | Where |
|------|-------|
| Component markup, via its preview | `spec/components/<name>_spec.rb` |
| Helper units | `spec/components/<name>_helper_spec.rb` |
| Behaviour in a real browser | `spec/system/` |
| The host installer | `spec/generators/` |
| The npm package contract | `spec/javascript/` |

Component specs are `type: :request`: they `get` the preview path and
parse the body with `Capybara.string` so DOM matchers can query it.
Helper specs are `type: :helper` and call `helper.render_<name>`
directly.

## Public API — changing it breaks consumers

Four surfaces reach into host apps. Treat a change to any of them as
breaking, and update the apps in `apps/` in the same commit:

- The `render_*` helpers. The engine is deliberately not
  namespace-isolated, so they are available in host views with no
  `include` — which also means renaming one breaks every caller.
- The npm package exports in `app/javascript/package.json`: `.`,
  `./controllers`, and `./application`. Hosts re-export `./application`
  so their own controllers register on the single Stimulus instance
  gesso starts.
- The Tailwind entry `app/assets/tailwind/gesso/engine.css`, which hosts
  reach as `@import "../builds/tailwind/gesso"` through tailwindcss-rails
  engine support.
- The installer at `lib/generators/gesso/install`, and what it writes
  into a host's `package.json`, Tailwind entry and JS entry.

## Running things

```sh
bundle exec rspec              # components, system, generators, package
bundle exec rake lint          # rubocop + herb; run after the specs pass
cd spec/dummy && bin/dev       # demo pages :3000, Lookbook :3000/lookbook
```

The dummy host at `spec/dummy` is a full Rails app consuming the engine
exactly as a real app does. It is the reference wiring — when a host
needs to be set up, copy what the dummy does.

## Shared Rails conventions

The Ruby and Rails conventions used across this repository — models,
controllers, testing, commit format — live in
`apps/clinical_exchange/.claude/rails/`. They are written for the apps,
but the style applies here too.
