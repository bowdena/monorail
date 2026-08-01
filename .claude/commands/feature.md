You are running the feature intake workflow. Do not write any code yet.

## Step 0 — Branch check

Run `git branch --show-current` before anything else.

Derive a suggested branch name from the feature description using the
`feat/<kebab-case-description>` convention (≤5 words, kebab-case).

**If on `main` or `master`:**

> ⚠️ You are on `main`. Features should be developed on a branch.
> Suggested branch: `feat/<kebab-case-description>`
> Run `git checkout -b feat/<kebab-case-description>` to create it,
> or tell me a different name.

Wait for confirmation before proceeding.

**If on any other branch:**

Assess whether the current branch name clearly encompasses this
feature's intent. If it does, proceed. If it doesn't (e.g. the branch
is named for an unrelated fix or a different feature), say so:

> You are on `<current-branch>`, which doesn't seem to cover this
> feature. Suggested branch: `feat/<kebab-case-description>`
> Run `git checkout -b feat/<kebab-case-description>` to create it,
> or confirm you want to continue on `<current-branch>`.

Wait for the user to either confirm the current branch or create a new
one before continuing.

Your job is to ask clarifying questions, synthesise the answers into a
structured plan, write the plan to disk, create tasks for each slice, and get
confirmation before any implementation begins.

## Step 1 — Ask clarifying questions

Ask questions **one at a time**, waiting for an answer before moving to
the next. If the feature description already answers a question clearly,
skip it and note the assumed answer.

**How to ask:**
- When a question has a predictable set of answers (approach choices,
  yes/no, multi-select constraints), use the `AskUserQuestion` tool so
  the user can select an option or choose "Other" to type a free-text
  answer.
- When a question is purely open-ended (describing a flow, listing edge
  cases), ask as plain text in your response and wait for a reply.
- Offer sensible defaults or the most likely answer as the first option.

Work through each of the following, adapting or skipping based on
context:

1. **Goal** — What is the user-visible outcome of this feature? One
   sentence.
2. **Who** — Which user or role performs this action?
3. **Happy path** — Walk me through the flow step by step from the
   user's perspective.
4. **Edge cases** — What can go wrong? What are the error states?
5. **Out of scope** — What are we explicitly not building in this
   iteration?
6. **Existing surface area** — Which models, controllers, or tables does
   this touch?
7. **Constraints** — Any performance requirements, permission rules,
   data migrations, or API compatibility concerns? Offer multi-select
   options: Performance, Permissions, Migrations, API compatibility,
   None.
8. **Implementation ideas** — Do you have specific ideas about how this
   should be built? Any patterns, gems, or approaches to use or avoid?
9. **Done** — How will we know this is complete? What does the
   acceptance test look like?

## Step 2 — Identify open questions

Based on the answers, identify anything ambiguous or that needs a decision
before implementation. List these and ask for resolution where possible. Do
not proceed until blockers are resolved.

## Step 3 — Write the plan

Read the guideline files for the application you are working in — for
`apps/clinical_exchange`, that is
`apps/clinical_exchange/.claude/rails/planning.md` for the plan structure and
slicing rules, and `apps/clinical_exchange/.claude/rails/git.md` for commit
conventions.

Write the plan to `docs/plans/<kebab-case-feature-name>.md` at the repository
root. Create `docs/plans/` if it does not exist.

The plan must include:

```markdown
# Feature: <name>

## Goal
One sentence.

## User Story
As a <who>, I want to <what>, so that <why>.

## Acceptance Criteria
- [ ] Observable outcome (not implementation detail)

## Implementation Notes
Specific ideas, patterns, or constraints the user provided.

## Out of Scope
- ...

## Open Questions
- Question → resolution (or "unresolved — needed before slice N")

## Slices

### Slice 1: <name>
**Commit:** `feat: <50-char message>`
**Files:** list files to create or modify
**Spec:** what the spec covers
**Status:** pending
```

Each slice maps to exactly one commit. Follow the commit message conventions from git.md.

## Step 4 — Present and confirm

Show the plan to the user. Ask:
- Does this capture the feature correctly?
- Are the acceptance criteria complete?
- Are the implementation notes correct?
- Is the slice order right, and does each slice feel commit-sized?
- Any changes before we start?

Do not proceed until the user explicitly confirms the plan.

## Step 5 — Create tasks

Once the plan is confirmed, create a task for each slice using the task system. Each task should include:
- The slice name and goal
- The planned commit message
- The spec file(s) to write

Mark the first task as `in_progress`. All others start as `pending`.

Report the task list to the user so they can see the full breakdown before work begins.

## Step 6 — Implement slice by slice

Detect whether each slice is a **refactor** or a **feature/fix** by its
commit prefix (`refactor:` vs `feat:`/`fix:`). The two tracks have
different rules.

---

### Track A — Feature / fix slices

#### 6a — Write the failing spec
Write the spec first. Show it to the user and confirm it captures the
intended behaviour before writing any implementation code.

#### 6b — Implement
Write the minimum code to make the spec pass. Follow the relevant
guideline files (models.md, controllers.md, frontend.md) as appropriate.

#### 6c — Verify
Run the spec file(s) for this slice only:
```
bundle exec rspec <spec/path/to/file_spec.rb>
```

Then run the linter:
```
bin/rails lint
```

If either fails: fix the issue, re-run, do not proceed until both pass.

#### 6d — Hand over for commit
Output the suggested commit message and files to stage. Wait for the
user to commit and confirm before continuing.

---

### Track B — Refactor slices

Refactors must not add new features or change observable behaviour.
Specs and implementation travel in **separate commits** in this order:

#### 6b-r1 — Confirm spec coverage first
Before writing any refactor code, check whether specs already cover the
surface area being changed:

- Search for existing specs touching the files/methods in scope.
- If coverage is adequate, note which specs will serve as the
  regression harness and proceed to 6b-r3.
- If coverage is missing or thin, go to 6b-r2.

#### 6b-r2 — Write coverage specs (separate commit)
Write specs that exercise the current behaviour — not the refactored
form. These specs must pass against the *existing* code before any
refactor changes are made. No implementation changes in this commit.

Hand over for commit with message `test: add coverage for <surface>`,
then wait for confirmation before continuing.

#### 6b-r3 — Implement the refactor
Make the structural change. Do not add new features, do not add or
update specs — the specs from 6b-r1/r2 are the unchanged harness.

#### 6b-r4 — Verify: targeted specs first, then full suite
First run only the spec file(s) covering the refactored surface:
```
bundle exec rspec <spec/path/to/file_spec.rb>
```

If those pass, run the **full test suite** to catch regressions:
```
bundle exec rspec
```

Then run the linter:
```
bin/rails lint
```

All three must pass before handing over. Fix any failures before
proceeding.

#### 6b-r5 — Hand over for commit
Output the suggested `refactor:` commit message and files to stage.
Wait for the user to commit and confirm before continuing.

---

### 6e — Update plan and tasks (both tracks)
- Mark the slice `Status: done` in `docs/plans/<feature-name>.md`
- Mark the task as `completed`
- Mark the next task as `in_progress`

### 6f — Pause and report (both tracks)
Report what was committed and what comes next. Wait for the user to
confirm before starting the next slice.

## Resuming after interruption

If the user returns to an in-progress feature, read
`docs/plans/<feature-name>.md`, find the first slice that is not `done`, check
git log to confirm what was committed, recreate tasks for the remaining
slices, then continue from the current slice.
