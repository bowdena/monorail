# Clinical Exchange — Claude Guidelines

These are the conventions for this application. Claude Code loads this file
automatically when you work on files under `apps/clinical_exchange/`, so every
developer on the project gets the same instructions without any setup.

Your personal `~/.claude/CLAUDE.md` still applies and layers on top of this
file. Where the two conflict on a codebase convention, this file wins — it
describes how *this* application is built.

Every file path in this document is relative to the application root,
`apps/clinical_exchange/`. Prefix them with that path when your working
directory is the repository root.

## Philosophy

"The best code is the code you don't write. The second best is the code that's
obviously correct."

- Prefer simple, readable code over clever code
- Small, focused commits over large changesets
- Favour native browser behaviour over custom javascript, such as popovers
  rather than modals
- Tests drive design — write the spec first, then the implementation
- Favour Rails conventions unless there is a clear reason to deviate
- Delete code that is no longer needed; do not comment it out

**Vanilla Rails is plenty:**
- Rich domain models over service objects
- CRUD controllers over custom actions
- Concerns for horizontal code sharing
- Records as state instead of boolean columns
- Database-backed everything (no Redis)
- Build solutions before reaching for gems

**Development Philosophy:**
- Ship, Validate, Refine - prototype-quality code to production to learn
- Fix root causes, not symptoms
- Write-time operations over read-time computations
- Database constraints over ActiveRecord validations

## Naming Conventions

**Verbs:** `card.close`, `card.gild`, `board.publish` (not `set_style` methods)

**Predicates:** `card.closed?`, `card.golden?` (derived from presence of related
record)

**Concerns:** Adjectives describing capability (`Closeable`, `Publishable`,
`Watchable`)

**Controllers:** Nouns matching resources (`Cards::ClosuresController`)

**Scopes:**
- `chronologically`, `reverse_chronologically`, `alphabetically`, `latest`
- `preloaded` (standard eager loading name)
- `indexed_by`, `sorted_by` (parameterized)
- `active`, `unassigned` (business terms, not SQL-ish)

## Ruby Syntax Preferences

Readability wins. Use these forms where they read clearly. Where a ternary
or an expression-less `case` makes the logic dense, use a plain `if`/`case`
with named intermediate variables instead.

```ruby
# Symbol arrays with spaces inside brackets
before_action :set_message, only: %i[ show edit update destroy ]

# Private method indentation
  private
    def set_message
      @message = Message.find(params[:id])
    end

# Expression-less case for conditionals
case
when params[:before].present?
  messages.page_before(params[:before])
else
  messages.last_page
end

# Bang methods for fail-fast
@message = Message.create!(params)

# Ternaries for simple conditionals
@room.direct? ? @room.users : @message.mentionees
```

## Success metric
Code follows style when:
- Controllers map to CRUD verbs on resources
- Models use concerns for horizontal behavior
- State is tracked via records, not booleans
- No unnecessary service objects or abstractions
- Database-backed solutions preferred over external services
- Tests use RSpec with Factories
- Turbo/Stimulus for interactivity (no heavy JS frameworks)
- Native CSS with modern features (layers, OKLCH, nesting)
- Jobs are shallow wrappers calling model methods

## Rails Self-Loading Rules

For configuration, architecture, routing, jobs, cache, auth please read
`.claude/rails/architecture.md`

When working on files in the following paths, read the corresponding guideline
file before making changes. Use the Read tool to load it.

| File path pattern    | Read this file                                        |
|----------------------|-------------------------------------------------------|
| `spec/**`            | `.claude/rails/tests.md`                              |
| `app/models/**`      | `.claude/rails/models.md`                             |
| `app/views/**`       | `.claude/rails/frontend.md`, `design_system.md`       |
| `app/helpers/**`     | `.claude/rails/frontend.md`, `design_system.md`       |
| `app/javascript/**`  | `.claude/rails/frontend.md`                           |
| `app/assets/**`      | `.claude/rails/frontend.md`                           |
| `app/controllers/**` | `.claude/rails/controllers.md`                        |
| `app/jobs/**`        | `.claude/rails/architecture.md`                       |
| `app/mailers/**`     | `.claude/rails/architecture.md`                       |
| `config/**`          | `.claude/rails/architecture.md`                       |
| `lib/**`             | `.claude/rails/architecture.md`                       |
| `db/**`              | `.claude/rails/architecture.md`                       |

Where two files are listed, read both. Bare filenames in the right-hand
column live in `.claude/rails/`.

When creating a commit, read `.claude/rails/git.md`.
When planning a feature or reviewing a plan document, read
`.claude/rails/planning.md`.

## Always-On Rules

These apply regardless of which files are being touched.

- Never generate secrets, credentials, or API keys
- Do not add commented-out code to commits
- Do not leave debugging output (puts, binding.pry, console.log) in committed
  code
- Prefer explicit over implicit — avoid magic that obscures intent
- One responsibility per class and method; concerns may bundle related
  associations, scopes, and methods for a single capability
- Rich domain models are the default; reach for service objects only when
  explicitly requested

### Line length

All files — code, planning documents, and documentation — use an 80-character
soft limit and a 120-character hard limit.

- Prefer wrapping at 80 characters.
- Never exceed 120 characters, except where a line break would change behaviour
  or surprise a user copying the content (e.g. a bare URL, a shell command that
  must be on one line). No other exceptions.

### Readability over terseness

Code should be approachable by a junior developer without explanation.
Where clarity and brevity conflict, choose clarity.

- Comments are a code smell. If code needs a comment to be understood,
  rename the method or variable, or extract a well-named method.
- Permitted comments: magic comments (`# frozen_string_literal: true`, the
  `locals:` comment in partials), and a short explainer for a regex or a
  non-obvious SQL fragment. Nothing else.
- Name methods and variables for what they mean in the domain, not for the
  mechanics of what they do.
- Prefer several clearly named steps over one dense expression.

### Rails tooling

Use the Rails generators rather than hand-writing the files they cover:
`bin/rails generate model|migration|controller|scaffold|job|mailer`.
`bin/rails db:migrate` and `bin/rails runner` are also fine to run.

- Run the generator first, then edit what it produced.
- Delete generator output that is not needed; do not leave it unused.
- Everything a single generator run produces — migration, model, spec, and
  the resulting `db/schema.rb` change — lands in one commit.
- Never run any `bin/rails credentials:*` command.

### YAGNI — build the minimum

Always implement the minimum that satisfies the stated requirement. Do not
add configuration options, extension points, generalisations, or
abstractions that are not needed right now. If a simpler approach works,
use it.

## Suggested Workflow

The rules above are binding. This section is not — it is how the team
prefers to work with Claude, offered so a new developer has a sensible
default. Override any of it in your own `~/.claude/CLAUDE.md` if a
different rhythm suits you better.

### Clarify before building

When a request is ambiguous — the scope is unclear, multiple valid
approaches exist, or an assumption would meaningfully change what gets
built — stop and ask at least 3 clarifying questions before writing any
code. Then provide a short explanation of the approach you will take and
the key trade-off(s) you considered, so the user can redirect if needed.

### Git — read only

Leave git writes to the developer. Never run `git commit`, `git push`,
`git checkout -b`, `git reset`, `git rebase`, or any other git command
that writes to the repository. Git reads (`git log`, `git diff`,
`git status`, `git branch`) are fine.

When a commit is ready, output the suggested commit message and the files
to stage. The developer runs the commit themselves.

### When building features
- Follow the rules in `.claude/rails/git.md` for commit message format.
- Each commit should be a thin slice with tests.
- Run only the specs changed to validate before handing over.
- Run `bin/rails lint` only after all specs pass.
- When a slice is ready, output the commit message and staged files, then
  pause and wait for the developer to commit and confirm before continuing.

### When fixing bugs
- Write the failing regression spec first — before any implementation.
- Implement the fix.
- Run the affected spec file(s) and confirm they pass.
- Run `bin/rails lint` only after specs pass.
- The regression spec ships in the same commit as the fix.
