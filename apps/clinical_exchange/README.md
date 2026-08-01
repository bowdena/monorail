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
