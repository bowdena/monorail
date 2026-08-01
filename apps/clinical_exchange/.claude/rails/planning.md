# Planning Guidelines

## When to Plan

Run `/feature` before writing any code for:
- Any new user-facing feature
- Any change that touches more than one model or controller
- Anything that will take more than one commit

Skip it for: bug fixes with a clear cause, single-file changes, dependency bumps.

## The Plan Document

Plans live at `docs/plans/<kebab-case-feature-name>.md` in the project repo.
Version-controlled, shareable, and resumable after interruption or context compression.

### Structure

```markdown
# Feature: <name>

## Goal
One sentence describing the user-visible outcome.

## User Story
As a <who>, I want to <what>, so that <why>.

## Acceptance Criteria
- [ ] Observable outcome — what the user sees or experiences, not implementation detail

## Implementation Notes
Specific patterns, gems, approaches, or constraints provided by the developer.

## Out of Scope
Explicit list of things not being built in this iteration.

## Open Questions
- Question → resolution, or "unresolved — needed before slice N"

## Slices
### Slice 1: <name>
**Commit:** `feat: <message following git.md conventions>`
**Files:** files to create or modify
**Spec:** what the spec for this slice covers
**Status:** pending | in-progress | done | dropped (<reason>)
```

## Writing Good Acceptance Criteria

Criteria must describe what a user can observe, not how the code works:

```
✅ A user receives an email when invited to a board
✅ The invitation link expires after 48 hours
❌ InvitationMailer#notify is called with the correct arguments
❌ expires_at is set to 48.hours.from_now
```

Each criterion should map to at least one spec and be independently verifiable.

## Capturing Implementation Ideas

During intake, capture any developer-provided opinions in **Implementation Notes**:
- Specific patterns to use or avoid ("use a form object for signup validation")
- Gem preferences ("use Pagy, not Kaminari")
- Architectural decisions ("keep this in the model, no service object")
- Known constraints ("this table has 2M rows, scope all queries through an index")

These notes inform the spec and implementation before any code is written.

## Slicing Rules

Each slice is a thin vertical cut — only the layers needed to produce testable behaviour.
Each slice maps to exactly one commit.
No slice should require another to be deployed first.
Order slices so the earliest ones produce visible, testable behaviour.
If a slice grows beyond one commit, re-slice it before starting.

### Recommended slice order for a new feature

1. Migration + model (schema, validations, associations, model concern if needed)
2. Model spec
3. Controller + routes
4. Request spec
5. View — minimal, enough to prove the flow works end-to-end
6. System spec
7. Polish, edge cases, error states — each as its own slice if substantial

## Task Tracking

When starting implementation, create a task for each slice. Tasks provide session-level
progress visibility and survive context compression within a session.

Each task holds:
- Slice name and goal
- Planned commit message
- Spec file(s) to write

Mark tasks `in_progress` when starting, `completed` when the commit is made.

## Before Each Commit

Both checks must pass before committing. No exceptions.

1. Run the spec file(s) for this slice:
   `bundle exec rspec <spec/path/to/file_spec.rb>`

2. Run the linter:
   `bin/rails lint`

Fix failures before committing. Do not skip with `--no-verify`.

## Slice Handoff — STOP and Wait

After each slice passes specs and lint, STOP. Output:

1. Suggested commit message (code block)
2. Files to stage
3. One sentence on what comes next

Then wait for the user to commit and confirm before starting the next
slice. Never implement more than one slice before a handoff.

## Resuming After Interruption

When returning to an in-progress feature:

1. Read `docs/plans/<feature-name>.md`
2. Find the first slice where Status is not `done`
3. Run `git log --oneline -10` to confirm what was actually committed
4. Update the plan if reality has diverged
5. Recreate tasks for the remaining slices
6. Continue from the current slice

## Updating the Plan

The plan is a living document. Update it when:
- A slice is completed → `Status: done`
- An open question is resolved → add the answer
- Scope changes → add to Out of Scope, or add a new slice
- Slice order changes based on what you learn

Never delete slices — mark them `done` or `dropped (<reason>)` so there is a clear record.
