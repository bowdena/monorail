# Feature: clinical_exchange test and lint harness

## Goal
Give clinical_exchange the same linting, RSpec/Capybara/Cuprite/FactoryBot
harness and `bin/ci` pipeline that thingz has, with no application tests
committed.

## User Story
As the developer, I want clinical_exchange wired with the same test and
lint tooling as thingz, so that I can write specs and run `bin/ci` from
the first feature without rebuilding the harness each time.

## Acceptance Criteria
- [ ] `bin/rails lint` runs herb lint, herb format check and RuboCop, and
      fails the run if any of them report offences
- [ ] `bin/rails lint:autocorrect` fixes herb formatting and RuboCop
      offences in place
- [ ] A system spec can drive a real headless Chrome through Cuprite
- [ ] `create(:thing)` and `build(:thing)` are available in specs without
      requiring FactoryBot explicitly
- [ ] shoulda-matchers one-liners are available in model specs
- [ ] System specs see committed data and leave a clean database behind;
      other specs roll back
- [ ] `bin/ci` runs setup, lint, gem audit, yarn audit, Brakeman and
      RSpec, and calls `gh signoff` only when every step passed
- [ ] `bin/ci` reports failure and skips signoff when any step fails
- [ ] No `*_spec.rb` or factory files are committed

## Implementation Notes
Reference implementation is `/home/bowdena/code/personal/thingz`. Copy its
pattern rather than inventing one.

- Lint is `lib/tasks/lint.rake`: `lint` depends on `lint:herb:check`,
  `lint:herb:formatcheck`, `lint:rubocop:check`; `lint:autocorrect`
  depends on `lint:herb:autocorrect` and `lint:rubocop:autocorrect`.
  Each task shells out and aborts with a message on failure.
- RuboCop config already inherits `rubocop-rails-omakase`. Leave it.
- Herb runs through yarn scripts (`herb:lint`, `herb:format`,
  `herb:format:check`) plus a `.herb.yml` config.
- `spec/support/database_cleaner.rb` picks `:deletion` for `type: :system`
  and `:transaction` for everything else, with
  `use_transactional_fixtures = false` in `rails_helper.rb`.
- `spec/system/support/cuprite_setup.rb` registers the `:cuprite` driver
  (1200x800, `no-sandbox`, headless unless `HEADLESS=false`,
  `INSPECTOR=true` for debugging) and sets `driven_by :cuprite` for
  system specs.
- `spec/system/support/precompile_assets.rb` precompiles assets before
  the suite when system or request specs are in the run.
- `spec/system_helper.rb` requires `rails_helper` then everything under
  `spec/system/support/`.

Deviations from thingz, deliberate:

- thingz runs `yarn audit`, which Yarn 4 removed. Use `yarn npm audit`.
- clinical_exchange generated with Yarn PnP. Switch to the
  `node-modules` linker so the herb and tailwind CLIs behave.
- thingz's `spec/support/authentication_helpers.rb` and the system
  sign-in helper are app-specific. Not ported — there is no auth yet.

`gh signoff` needs `gh extension install basecamp/gh-signoff` on any
machine that runs `bin/ci`. Not automated by this work.

## Out of Scope
- webmock and VCR — no external HTTP calls yet
- Any `*_spec.rb` file or factory committed to the repo
- GitHub Actions workflow (monorail has no `.github/` at all)
- mise task wiring for `ci` from the monorepo root
- Authentication helpers ported from thingz
- Kamal/deploy configuration

## Open Questions
- Which test-stack extras? → shoulda-matchers, database_cleaner and herb.
  webmock/vcr dropped.
- PnP or node_modules? → node_modules, via `.yarnrc.yml`.
- How to verify with no tests committed? → write throwaway specs, run
  them, delete before handover.
- How far does CI wiring go? → `config/ci.rb` plus `gh signoff` only.

## Slices

### Slice 1: Yarn node-modules linker
**Commit:** `chore: switch yarn to node-modules linker`
**Files:** `.yarnrc.yml` (new), `.gitignore`, `yarn.lock`, removal of
`.pnp.cjs` and `.pnp.loader.mjs`
**Spec:** none — verified by `yarn install` succeeding and `yarn build`
plus `yarn build:css` producing output in `app/assets/builds`
**Status:** done — `yarn.lock` was unchanged; `.yarn/install-state.gz`
needed untracking as well

### Slice 2: Herb linting and rails lint task
**Commit:** `chore: add herb linting and rails lint task`
**Files:** `Gemfile`, `Gemfile.lock`, `package.json`, `yarn.lock`,
`.herb.yml` (new), `lib/tasks/lint.rake` (new)
**Spec:** none — verified by `bin/rails lint` passing on the generated
app and failing when a deliberate offence is introduced
**Status:** pending

### Slice 3: RSpec test harness
**Commit:** `chore: add rspec test harness`
**Files:** `Gemfile`, `Gemfile.lock`, `spec/rails_helper.rb`,
`spec/system_helper.rb` (new), `spec/support/database_cleaner.rb` (new),
`spec/system/support/cuprite_setup.rb` (new),
`spec/system/support/precompile_assets.rb` (new), `spec/factories/.keep`
**Spec:** throwaway model and system specs proving factory_bot,
shoulda-matchers, database_cleaner and cuprite all work — deleted before
handover, not committed
**Status:** pending

### Slice 4: bin/ci runs specs and signs off
**Commit:** `chore: run rspec and signoff from bin/ci`
**Files:** `config/ci.rb`
**Spec:** none — verified by a full `bin/ci` run going green
**Status:** pending
