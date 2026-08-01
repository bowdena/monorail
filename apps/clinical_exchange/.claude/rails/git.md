# Git Behaviour Guidelines

## Commit Size

- One logical change per commit — a reviewer should be able to understand it without context from other commits
- A commit is "commit-sized" if it can be described in a subject line of 50 characters or fewer
- If a commit touches model, controller, view, and spec for the same feature, that is acceptable — that is a thin slice
- If a commit touches two unrelated features, split it
- A single generator run is a single commit — the migration, the model, the
  spec, and the `db/schema.rb` change it produced all go together

## Commit Messages

- Subject line: imperative mood, ≤50 chars, no trailing period —
  "Add user authentication" not "Added user authentication"
- Use Conventional Commits format: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- Body (when needed): explain WHY, not what — the diff shows what
- Do not reference line numbers or variable names in the message; those rot

## What to Include

- Never commit:
  - `.env` files or any file containing secrets
  - `binding.pry`, `debugger`, `console.log`, `puts` used for debugging
  - Commented-out code
  - Generated files that are in `.gitignore`
- Always commit:
  - The spec alongside the implementation it covers
  - Schema changes (`db/schema.rb`) alongside the migration that generated them

## Branch Strategy

- Branch names: `feat/short-description`, `fix/short-description`, `chore/short-description`
- Keep branches short-lived — merge or rebase frequently against main
- Do not commit directly to main

## Slice Handoff Protocol

After completing each slice, STOP. Do not proceed to the next slice until
the user confirms.

Output exactly:

1. The suggested commit message (formatted as a code block)
2. The list of files to stage
3. A one-line note on what the next slice will do

Then wait. The user commits, then confirms. Only continue when they do.
Never batch multiple slice handoffs in one response.
