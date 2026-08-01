# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

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
