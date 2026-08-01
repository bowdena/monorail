# Feature: GitHub CI for clinical_exchange

## Goal
Every push that touches `apps/clinical_exchange` or `gems` runs herb,
rubocop and brakeman in parallel on GitHub, then runs the RSpec suite
only once all three pass.

## User Story
As the developer of this monorepo, I want CI to lint and test
clinical_exchange automatically on every branch push, so that I find
broken style, security warnings and failing specs before I merge,
without paying for runner time on pushes that do not touch the app.

## Acceptance Criteria
- [ ] Pushing a branch that changes a file under
      `apps/clinical_exchange/` starts the workflow
- [ ] Pushing a branch that changes a file under `gems/` starts the
      workflow, because the app compiles against the gesso path gem
- [ ] Pushing a branch that changes only unrelated files (README,
      docs/) starts no workflow run
- [ ] The workflow runs on pushes to `main` as well as feature branches
- [ ] `herb`, `rubocop` and `brakeman` run as three parallel jobs
- [ ] The `test` job does not start until all three linting jobs pass,
      and is skipped when any of them fails
- [ ] The `test` job runs the full suite, including the Capybara system
      spec, against a real Postgres and headless Chrome
- [ ] A failing rubocop offence, a brakeman warning, or a failing spec
      each turn the run red
- [ ] `yarn install` in CI resolves the same dependency tree as local

## Implementation Notes

**Workflow location.** GitHub only reads `.github/workflows` at the
repository root, so the workflow lands at
`.github/workflows/clinical_exchange.yml`. The existing
`apps/clinical_exchange/.github/workflows/ci.yml` has never run — it is
`rails new` output, and it targets `master` while the default branch is
`main`.

**Job graph.**

```
herb ─┐
rubocop ─┼─→ test
brakeman ─┘
```

`bin/rails lint` bundles herb *and* rubocop. Since rubocop is its own
job, the herb job calls the yarn scripts directly
(`yarn herb:lint`, `yarn herb:format:check`) so rubocop does not run
twice. The herb job needs Node only — no Ruby setup.

**Path filter.**

```yaml
paths:
  - "apps/clinical_exchange/**"
  - "gems/**"
  - ".github/workflows/clinical_exchange.yml"
```

`gems/**` covers both gesso and conduit: a change to either should
re-run every app's CI, and clinical_exchange is currently the only app.

**Toolchain.** `ruby/setup-ruby` reads `.ruby-version` (4.0.6) and
`actions/setup-node` reads `.node-version` (26.5.1), so no version is
duplicated in the workflow. Both need an explicit
`working-directory` / `cache-dependency-path` pointing at
`apps/clinical_exchange`, since the repo root has no Gemfile.

Yarn is the exception: the runner's default `yarn` is v1 and cannot
read a `__metadata: version: 10` lockfile. A `packageManager` field in
`package.json` plus `corepack enable` pins it to 4.18.0, matching the
root `mise.toml`.

**Postgres.** A `postgres:18` service container, with `PGHOST`,
`PGPORT`, `PGUSER` and `PGPASSWORD` exported as env vars. That leaves
`config/database.yml` untouched and mirrors how the local mise tasks
connect. The app has no migrations yet, so `bin/rails db:prepare`
simply creates the empty test database that `maintain_test_schema!`
and DatabaseCleaner expect.

**Assets.** `spec/support/precompile_assets.rb` drives
`assets:precompile` (tailwind + `yarn build`) inside the suite, so the
test job only needs `yarn install` beforehand — no separate build step.

**Chrome.** `ubuntu-latest` ships Chrome, and `cuprite_setup.rb`
already runs headless with `--no-sandbox`, so the system spec should
work with no extra setup. If cuprite cannot find the binary, the fix is
`browser_path: ENV["CHROME_PATH"]` rather than installing a browser.

**Caching.** `bundler-cache: true` for gems, and the rubocop
`actions/cache` block carried over from the dead `ci.yml` — kept as
generated Rails boilerplate, with its paths rewritten to be
workspace-relative. It buys little while the app is small (32 files
inspect in 1.2s cold) and earns its keep as the app grows.

`setup-node`'s built-in `cache: yarn` cannot be used here. It probes
the cache directory before any step of ours runs, so it invokes the
runner's Yarn 1, which hard-errors on a `packageManager` field rather
than degrading. Corepack is enabled first instead, and the cache path
comes from `yarn config get cacheFolder` — Yarn 4 puts its global cache
under `~/.local/share/yarn/berry`, not the `~/.yarn` path a hardcoded
guess would use.

**Concurrency.** One in-flight run per ref, `cancel-in-progress: true`,
so a fast follow-up push supersedes the previous run.

## Out of Scope
- `bundler-audit` and `yarn npm audit` — these stay local, run through
  `bin/ci`
- The `gh signoff` step from `bin/ci` — the Actions run is itself the
  commit status
- CI for `gems/gesso` and `gems/conduit` own specs — `gems/**` triggers
  the *app* suite only
- `pull_request` triggers — push covers same-repo branches, and adding
  both double-runs each commit
- A reusable/matrix workflow for future apps — YAGNI while
  clinical_exchange is the only app
- Deployment, Docker builds, Kamal

## Open Questions
- Job layout → three parallel lint/scan jobs gating a `test` job
- Which security scans → brakeman only; audits stay local
- Path filter scope → app folder plus all of `gems/`
- Trigger → every branch push, including `main`
- System specs → included, full suite
- Toolchain → `setup-ruby` + `setup-node`, yarn pinned via
  `packageManager`
- Dead app-level `.github` → `ci.yml` deleted, `dependabot.yml` lifted
  to the repo root
- Does cuprite find Chrome on `ubuntu-latest`? → unresolved, verified
  by the first real run in slice 2

## Slices

### Slice 1: Pin the Yarn version
**Commit:** `chore: pin yarn to 4.18.0 via packageManager`
**Files:** `apps/clinical_exchange/package.json`
**Spec:** No spec — verified by `corepack enable && yarn install
--immutable` leaving `yarn.lock` unchanged, and `yarn --version`
reporting 4.18.0.
**Status:** done

### Slice 2: Add the CI workflow
**Commit:** `chore: run clinical_exchange CI on GitHub`
**Files:** create `.github/workflows/clinical_exchange.yml`, delete
`apps/clinical_exchange/.github/workflows/ci.yml`
**Spec:** No RSpec coverage — YAML workflows are verified by the run
itself. Acceptance is a green run on this branch, plus a docs-only
push that triggers nothing.
**Status:** done

### Slice 3: Lift dependabot to the repo root
**Commit:** `chore: move dependabot config to the root`
**Files:** create `.github/dependabot.yml`, delete
`apps/clinical_exchange/.github/dependabot.yml`
**Spec:** No spec — verified by GitHub accepting the config on the
repository's Dependabot settings page.
**Status:** in-progress

The generated config assumed a single-app repo and pointed bundler at
`/`, where there is no Gemfile. The root version uses `directories:`
to cover the app and both gems, adds the npm ecosystem for the app's
`package.json`, and keeps github-actions pointed at the root, which is
now where the workflow actually lives.
