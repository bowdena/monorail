# Feature: Merge-aware patient searching via MERGE_MINOR_FLAG

## Goal
Patient name searches return only current records, and a URN lookup
skips the merge tables entirely unless the patient's own row says it
was merged away.

## User Story
As a clinician searching for a patient, I want name searches to return
only the patient's current record, so that I am never shown a
superseded identity and the search does not pay for merge resolution
that almost never applies.

## Acceptance Criteria
- [ ] A name search returns only current records; a record that was
      merged into another never appears in the results
- [ ] A name search that matches only a patient's former name returns
      no results
- [ ] Name search results stay ordered by surname, then forename
- [ ] A URN lookup for a patient who was never merged returns that
      patient without reading MERGED_PATIENTS at all
- [ ] A URN lookup for a merged-away patient still returns the current
      record and reports the URN that was searched
- [ ] A multi-hop merge chain still resolves to the record at its end
- [ ] A cyclic merge chain still terminates rather than spinning
- [ ] A URN lookup whose chain ends at an archived patient returns
      nothing

## Background

Findings from the production MERGED_PATIENTS extract (2.3M rows,
2026-08-06) that this feature rests on:

- `MERGE_MINOR_FLAG = 'Y'` marks the losing side of a merge. Across
  the 77 patients available it identifies the 29 merged-away records
  exactly — no false positives, no misses.
- Merged-away records keep `ARCHV_FLAG = 'N'`. Archiving was never the
  merge signal, so the existing `active` scope does not exclude them.
- The flag is current state, not history: a record that absorbs
  another and is later absorbed itself flips to `'Y'`. Two of the 77
  are in exactly that position.
- Merges are shallow. Of 144,099 distinct merges, 140,270 are a single
  hop and only one chain exceeds three.
- MERGED_PATIENTS writes one row per record moved, not one per merge:
  2.3M rows describe 144,099 merges, one pair repeating up to 3,649
  times.
- No patient has two different active merge targets. Including
  archived rows, 72 do — the `ARCHV_FLAG` filter is what makes the
  data unambiguous.

## Implementation Notes

- **No temporary tables.** Nothing in this feature may create one.
- **Walk in Ruby**, not SQL. No recursive CTEs — the chain is at most
  a handful of hops and Ruby reads more plainly.
- **Delete MergeResolver.** Its remaining job is one walk with one
  caller. Fold it into `Repositories::Patients` as a private method;
  the class and its unit spec go away, with `spec/integration/
  ur_search_spec.rb` serving as the regression harness.
- **Ordering moves into the relation** as `ORDER BY upper_surname,
  upper_forename`, using the same columns names are matched on.
- **Hop query drops its sort.** `SELECT DISTINCT PATNT_REFNO` rather
  than `ORDER BY create_dttm DESC LIMIT 1`; the sort scans thousands
  of duplicate rows on an unindexed column for an answer that never
  varies.
- **A flagged row with no merge rows returns itself** — chain ends
  where it starts, `merged_from` nil. Same as today's behaviour when
  no target is found.
- `PREV_PATNT_REFNO` is unindexed in iPM, so each hop scans. That is
  a DBA change, not a gem change, and is out of scope — but it is the
  reason skipping the lookup for unflagged patients matters.

## Out of Scope
- Any index change on the iPM database
- `Patient` struct and `PatientMapper` — `merged_from` and `merged?`
  stay exactly as they are
- Turning the redacted production extract into a spec fixture
- Precomputed merge lookup tables, temporary or permanent
- Changing what a chain ending at an archived patient returns (nil)

## Open Questions
- Former-name searches → resolved: dropped. Name searches return
  current records only.
- Where merge resolution lives → resolved: folded into
  `Repositories::Patients`, `MergeResolver` deleted.
- Hop query shape → resolved: distinct target, take it. No raise on
  ambiguity; the condition does not exist while `ARCHV_FLAG` is
  filtered.
- Flagged row with no merge row → resolved: return the row itself.
- Result ordering → resolved: into the relation.
- Slice 5 commit type → `perf:` is not in git.md's list. Proposed
  anyway as the honest description; say the word and it becomes
  `refactor:`.

## Validation before release

Everything here rests on `MERGE_MINOR_FLAG = 'Y'` meaning "this record
was merged away". That equivalence is proven on 29 positives in a
77-patient sample, not across production. Run this against a full
production `PATIENTS` extract before shipping, and carry the result in
the PR description.

```sql
SELECT COUNT(*) AS survivors_wrongly_flagged
FROM PATIENTS p
WHERE p.MERGE_MINOR_FLAG = 'Y'
  AND p.ARCHV_FLAG = 'N'
  AND NOT EXISTS (
    SELECT 1 FROM MERGED_PATIENTS m
    WHERE m.PREV_PATNT_REFNO = p.PATNT_REFNO
      AND m.ARCHV_FLAG = 'N'
  );
```

**Looking for zero.** Any other number counts patients the gem would
treat as merged away while `MERGED_PATIENTS` offers nowhere to resolve
them to. Those patients still return their own record — slice 4's
fallback — so a non-zero result is not a failure, but it does mean the
flag and the merge table disagree in production, and the count is how
badly. A handful is data noise worth naming in the PR. Thousands would
mean the flag carries a meaning this feature has not accounted for,
and the name-search exclusion in slice 2 would be hiding live patients
from search — stop and re-examine before merging.

The inverse is worth a look too, though it is not a blocker: patients
with an active `MERGED_PATIENTS` row whose own record is *not* flagged
would mean the flag misses real merges, which name searches would then
return as duplicates.

```sql
SELECT COUNT(*) AS merged_but_unflagged
FROM PATIENTS p
WHERE p.MERGE_MINOR_FLAG <> 'Y'
  AND p.ARCHV_FLAG = 'N'
  AND EXISTS (
    SELECT 1 FROM MERGED_PATIENTS m
    WHERE m.PREV_PATNT_REFNO = p.PATNT_REFNO
      AND m.ARCHV_FLAG = 'N'
  );
```

## Slices

### Slice 1: Flag the merged-away seed fixtures
**Commit:** `test: flag merged-away patients as merge minor`
**Files:**
- `spec/support/mssql_integration_seeds/iPM_REPL/PATIENTS.sql`

Sets `MERGE_MINOR_FLAG = 'Y'` on the five merged-away fixtures:
9000001 (Ava Prior), 9000002 (Pryor), 9000005 (Ivy Knot), 9000006
(Ivy Loop), 9000007 (Sam Holt). All others stay `'N'`. 9000005 and
9000006 are the deliberately cyclic pair, so both carry the flag and
the walk must still terminate.

Prerequisite commit: no code reads the flag yet, so the whole suite
must stay green unchanged. Without it every flag-based filter added
later would pass for the wrong reason.

**Spec:** none new. Full suite green proves the seeds are inert.
**Status:** done — 101 examples, 0 failures; rubocop clean.

Note on running the specs: the seeder aborts if any seeded table
exceeds 1,000 rows, and it DELETEs both tables before reinserting, so
it cannot run against the instance holding the production extract.
Specs run against a throwaway `conduit-mssql-specs` container on 1433
while `conduit-mssql-1` is stopped with its data intact.
`source_down_spec` deletes CONDUIT_MSSQL_PORT to prove recovery, so
the seeded instance has to be on the default port — a second instance
on 1434 fails that example.

### Slice 2: Exclude merged-away records from name search
**Commit:** `feat: exclude merged-away records from search`
**Files:**
- `lib/conduit/ipm/relations/patients.rb`
- `lib/conduit/ipm/repositories/patients.rb`
- `spec/integration/patient_matching_spec.rb`

Adds `merge_minor_flag` to the relation schema and a `current` scope
(`active` plus `merge_minor_flag != 'Y'`) ordered by `upper_surname`,
`upper_forename`. `exact_match` and `fuzzy_match` start from
`current`; `by_pasid` stays on `active` so a merged-away URN can still
be found and resolved. `find_all_by` and `matching` stop calling
`resolve_all` and map rows directly.

**Spec:** `spec/integration/patient_matching_spec.rb`. Two existing
examples change meaning and are rewritten: "when a match is reachable
only via merge" becomes a former-name search returning no results, and
"matches partial names, ignoring case" moves to a term that hits a
current record. Ordering and archived-exclusion examples must keep
passing untouched.
**Status:** pending

### Slice 3: Fold merge resolution into the repository
**Commit:** `refactor: fold merge resolution into repository`
**Files:**
- `lib/conduit/ipm/merge_resolver.rb` (delete)
- `spec/conduit/ipm/merge_resolver_spec.rb` (delete)
- `lib/conduit/ipm/repositories/patients.rb`
- `lib/conduit.rb`

Track B refactor. Coverage check first: `spec/integration/
ur_search_spec.rb` already exercises a direct hit, a one-hop merge, a
two-hop chain, an archived patient, a chain ending at an archived
patient, a cycle, and a miss. That is the harness — no new coverage
commit needed. Confirm before touching code.

`by_urn` walks the chain in a private method. No behaviour change and
no flag use yet; that is slice 4.

**Spec:** none written or changed. Targeted `ur_search_spec.rb`, then
the full suite, then lint.
**Status:** pending

### Slice 4: Skip the merge lookup for unflagged patients
**Commit:** `feat: skip merge lookup for unmerged patients`
**Files:**
- `lib/conduit/ipm/repositories/patients.rb`
- `spec/integration/ur_search_spec.rb`

`by_urn` reads `merge_minor_flag` on the row it already fetched and
returns immediately unless it is `'Y'`. MERGED_PATIENTS is never
touched for the ~62% of patients who were never merged away.

**Spec:** a guardrail example asserting no MERGED_PATIENTS query is
issued for an unflagged patient, via `Conduit.on_query`. Its `it`
block should say plainly that it guards an assumption rather than a
behaviour — nothing a caller can observe changes if it regresses, and
the flag/merge-table agreement it leans on is asserted from a sample,
not proven for all production data. Wording to be agreed when written.
**Status:** pending

### Slice 5: Collapse duplicate rows in the hop query
**Commit:** `perf: collapse duplicate rows in merge hop query`
**Files:**
- `lib/conduit/ipm/relations/merged_patients.rb`
- `lib/conduit/ipm/repositories/patients.rb`

Replaces `latest_target` with `target_for`: `SELECT DISTINCT
PATNT_REFNO WHERE PREV_PATNT_REFNO = ? AND ARCHV_FLAG = 'N'`, no sort.
Tie-breaking by recency becomes arbitrary selection, which is
equivalent while no patient has two active targets — none of the
144,099 does.

**Spec:** existing `ur_search_spec.rb` examples cover it, including
the archived-row fixture that must still be ignored. No new spec
unless the rewrite exposes a gap.
**Status:** pending
