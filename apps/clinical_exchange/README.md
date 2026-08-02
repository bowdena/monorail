## Database conventions

### Primary keys are UUIDv7

Records appear in URLs, so tables are keyed by a version 7 UUID rather
than a sequential id — a `/patients/1234` scheme lets anyone walk the
table. Version 7 is time-ordered, so ids still insert at the end of the
index instead of scattering as version 4 does.

Postgres 18 provides `uuidv7()` natively; no extension is installed.

Rails does not generate version 7 ids. `create_table id: :uuid` uses
`gen_random_uuid()` — version 4 — and Rails 8.1 has no knowledge of
`uuidv7`. `config/initializers/generators.rb` sets the generated key
*type*; each migration names the function:

```ruby
create_table :appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
  t.references :patient, type: :uuid, foreign_key: true
  t.timestamps
end
```

Omitting the `default:` is silent — the table works, the ids are just
random. After migrating, check `db/schema.rb` shows
`id: :uuid, default: -> { "uuidv7()" }` for the new table.

## iPM access through conduit

Patient data is read from the iPM replica through the `conduit` gem. The
application supplies only its identity — its own login for each source
it reads. The login must be SELECT-only.

### Credentials

Each environment has its own encrypted file and its own key, so a test
run can never hold production's login. Both live under
`config/credentials/`:

| Environment | File                    | Key                |
|-------------|-------------------------|--------------------|
| development | `development.yml.enc`   | `development.key`  |
| test        | `test.yml.enc`          | `test.key`         |
| production  | `production.yml.enc`    | `production.key`   |

The `.key` files are gitignored and never committed. Edit a file with:

```sh
bin/rails credentials:edit --environment development
bin/rails credentials:edit --environment test
bin/rails credentials:edit --environment production
```

Each one holds the same shape. Development and test point at the local
MSSQL container, production at the real replica:

```yaml
conduit:
  ipm:
    username: clinical_exchange
    password: <the password for that login>
```

`config/initializers/conduit.rb` reads exactly those two values, so a
missing or misspelled key fails at boot rather than at the first query.

### The CI key

CI checks out the encrypted files but not the keys, so it decrypts the
test credentials with the `RAILS_MASTER_KEY` variable — Rails' fallback
for whichever environment file is active. Add it once:

1. Copy the contents of `config/credentials/test.key`.
2. On GitHub, open the repository's **Settings** → **Secrets and
   variables** → **Actions**.
3. **New repository secret**, named `RAILS_MASTER_KEY`, with that value.

The test workflow passes it through as an environment variable. It
protects dummy credentials only — never put the production key there.

## Coding conventions for Claude Code

The conventions for this application are checked into the repository so every
developer works to the same standard. There is nothing to install or
configure — Claude Code picks these up automatically.

- `CLAUDE.md` — the entry point. Philosophy, naming, Ruby style, and the
  always-on rules. Loaded whenever you work on files in this application.
- `.claude/rails/*.md` — deeper guidance for one area each: `architecture.md`,
  `controllers.md`, `frontend.md`, `git.md`, `models.md`, `planning.md`,
  `tests.md`. `CLAUDE.md` tells Claude which of these to read based on the
  files being changed, so you rarely need to name one yourself.

The "Suggested Workflow" section of `CLAUDE.md` is the team's preferred rhythm
rather than a rule. Override any of it in your own `~/.claude/CLAUDE.md`.

Two slash commands live at the repository root in `.claude/commands/`:

- `/feature` — feature intake. Asks clarifying questions, writes a sliced plan
  to `docs/plans/`, then implements one commit-sized slice at a time.
- `/pr` — generates a pull request summary for the current branch.

When you change a convention, change the file it lives in and commit it. These
documents are the source of truth, not a snapshot of someone's local setup.
