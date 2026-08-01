Generate a pull request summary for the current branch and print it to the
CLI in markdown so the user can copy and paste it into GitHub.

## Step 0 — Branch check

Run `git branch --show-current` before anything else.

If the current branch is `main` or `master`, warn the user:

> ⚠️ You are on `main`. A PR summary from main has no diff to review.
> Do you want to continue anyway?

Wait for confirmation before proceeding.

## Step 1 — Gather context

Run the following to understand what this PR contains:

```
git log --oneline origin/main..HEAD
git diff origin/main..HEAD --stat
git diff origin/main..HEAD
```

If a plan file exists at `docs/plans/*.md` that matches this branch or
feature, read it for the goal, acceptance criteria, and implementation notes.

## Step 2 — Generate the document

Output the PR summary to the terminal as raw markdown. Do not wrap it in a
code block — it must be directly copy-pasteable into GitHub.

### Formatting rules

- All lines must be 80 characters wide or fewer
- Wrap prose at 80 characters; do not wrap code inside fenced blocks
- Code snippets use fenced blocks with a language tag:

  ```ruby
  def example
  end
  ```

- References to specific methods, classes, modules, or files use single
  backticks: `UserInvitationsController`, `Closeable#close`, `schema.rb`
- Use `##` for top-level sections, `###` for subsections
- Use `-` for bullet lists, not `*`
- Do not use HTML

### Document structure

---

## What

One paragraph (≤5 sentences) describing what this PR does from the user's
perspective. Focus on the outcome, not the implementation.

## Why

One paragraph explaining the motivation. Why does this change need to
exist? What problem does it solve?

## Manual testing required

Only include this section if there are behaviours that cannot be covered by
specs — for example: browser-specific behaviour, file uploads, email
rendering, OAuth flows, or third-party integrations.

If everything is covered by specs, omit this section entirely.

When present, provide numbered steps: what to do, what to enter, what to
expect.

## Notes for reviewer

Only include this section if there is something a reviewer needs to know
that is not obvious from reading the diff:
- Non-obvious design decisions and the reason for them
- Known trade-offs accepted in this PR
- Follow-up work deferred to a future PR
- Anything that looks surprising but is intentional

If there is nothing to flag, omit this section entirely.

---

Print only the markdown document. No preamble, no explanation, no trailing
comment. The first character of output must be `##`.

Output the document inside a fenced markdown code block so it renders as
plain copyable text rather than formatted markdown in the terminal. Begin
with a `# Title` line followed by a blank line, then the sections:

```
# Add user avatar upload

## What
...
```

The title should be ≤60 characters, imperative mood, no trailing period.
