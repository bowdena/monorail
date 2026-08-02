# Feature: Conduit patient search pagination

## Goal

A consumer searching iPM patients by name or date of birth chooses a page
size, walks the result set page by page, and can tell how many pages there
are.

## User Story

As an application consuming conduit, I want name and date-of-birth patient
searches to return one page of records at a time along with the totals, so
that I can show a user a manageable list and let them step through the rest.

## Acceptance Criteria

- [ ] `find_all_by` and `matching` accept `page:` and `per_page:` and return
      only that page's records
- [ ] A caller that passes neither gets every match, as one page
- [ ] The returned page reports `total_count` and `total_pages` for the whole
      result set, not just the page
- [ ] The returned page reports where it sits: `current_page`, `next_page`,
      `previous_page`, `first_page?`, `last_page?`
- [ ] Page numbering is stable — page 2 of a search returns the same records
      on every request, and no patient appears on two pages
- [ ] Totals count patients, after merge collapse, not raw matched rows
- [ ] A search big enough to page through succeeds rather than being refused
      — paginating a broad search is the remedy, not a thing the cap blocks
- [ ] Resolving a match set costs a handful of queries whatever its size, not
      one per matched row
- [ ] A search matching more than 2000 rows raises
      `Conduit::Error::TooManyResults` naming the number that matched, rather
      than running the search
- [ ] Asking for a page beyond the last raises `ArgumentError`; page 1 of a
      search with no matches does not
- [ ] `page` or `per_page` below 1 raises `ArgumentError`
- [ ] The audit event for a paged query records the page the caller asked for
      and identifies only the records on that page
- [ ] An out-of-range page leaves an audit event carrying the error, not a
      trace that looks like an empty result

## Implementation Notes

### Why pagination cannot happen in SQL

Merge resolution runs in Ruby, after the fetch. `MergeResolver#resolve_all`
follows each matched row's merge chain, **collapses** rows resolving to the
same patient, and **sorts** by the resolved record's surname and forename. A
merged-away row resolves to a patient with a different name, so the SQL
ordering is not the final ordering.

`OFFSET`/`FETCH` in the relation would therefore page over pre-resolution
rows: a page of 25 rows could yield fewer records after collapse, page
boundaries would not line up with the sorted output, the same patient could
appear on two pages, and `COUNT(*)` would count rows rather than patients.

So: fetch the match set, resolve, then slice in Ruby.

### Why merge resolution has to be batched first

Because resolution runs over the whole match set before anything can be
sliced, pagination cannot reduce what resolution costs — knowing which 25
patients sit on page 2 means resolving all of them. Any cap on the match set
therefore applies whether or not the caller paginates. A cap low enough to
bound the current per-row cost would refuse exactly the broad searches
pagination exists to serve.

The per-row cost is not inherent, it is an N+1. `MergeResolver#resolve` runs
per row:

- `latest_target` once, minimum — an unmerged row still costs a query to
  learn it was never merged
- one more per merge hop
- one `active_by_refno` when the chain moved

So an unmerged row costs one query and a one-hop merged row costs three: a
1247-row match is roughly 1247 round trips.

Resolved as a set instead, the same work is bounded by chain depth rather
than row count — one query per generation of the merge graph, then one to
load the resolved rows. Chains are typically a single hop, so a match set of
any size costs three or four queries.

`resolve` and `resolve_all` both stay, reimplemented on one batched core, so
`by_urn`'s single-row path and the collection paths share an implementation.
Cycle detection has to survive the rewrite: chains are followed generation by
generation, and a refno already seen on a chain ends it.

### Why the result set is still capped

Not for cost, once batched — for the `IN` list. SQL Server refuses a
statement with more than 2100 parameters, so `MAX_RESULTS = 2000` keeps every
batched lookup comfortably inside one statement and removes any need to chunk.
The cap is a ceiling on what one search may return, not a budget for round
trips.

The count is of rows, pre-collapse, so error messages say "matches", never
"patients".

### API shape

`find_all_by` and `matching` always return a `Conduit::Page`, never a bare
Array. One return type, no branching on what the caller asked for. `Page`
includes `Enumerable` and defines `length` and `empty?`, so existing
iteration keeps working — including `Array(...)` in clinical_exchange's
`Patient.found_in_ipm`, which needs no change.

```ruby
patients = Conduit.ipm.patients

page = patients.matching(last_name: "jud", page: 2, per_page: 25)

page.records        # => [Patient] — this page only
page.current_page   # => 2
page.per_page       # => 25
page.total_count    # => 63    patients, after merge collapse
page.total_pages    # => 3
page.next_page      # => 3, or nil on the last page
page.previous_page  # => 1, or nil on the first
page.first_page?    # page.last_page?
page.length         # page.empty?
page.each { }       # Enumerable — map, select, to_a
```

Defaults are `page: 1, per_page: nil`. A nil `per_page` means one page holding
everything, so `total_pages` is 1, or 0 when nothing matched. No default page
size is invented — explicit over implicit.

`Page.of(records, page:, per_page:)` is the single home for validation and
slicing; the repository stays thin.

### Validation rules

- `page < 1` or `per_page < 1` — a caller bug, checked before the query runs.
  No query, no audit event, same treatment as all-blank criteria today.
- `page > total_pages` — only knowable after the query, so the round trip is
  already spent. Raises `ArgumentError` naming both numbers.
- Page 1 is always valid. A search with no matches returns an empty page with
  `total_count` 0 and `total_pages` 0 — no results is an ordinary outcome, not
  a caller bug.

### Audit

`params` gains `page` and `per_page`. `row_count` and `record_ids` describe
the page, not the whole result set — the audit trail records what the user
actually saw. `QueryEvent`'s nine keys are unchanged, so no consumer breaks.

Two changes in `Conduit::Repository`:

- `audited` counts with `count` rather than `length`, so an Enumerable `Page`
  works through the same path as the existing array returns. No new helper.
- `audited` rescues `ArgumentError` alongside `Error`, so an out-of-range page
  is tagged on the event and re-raised. Without this an overrun emits an event
  with no `row_count` and no `error` — indistinguishable from a query that
  matched nothing.

### Error taxonomy

`Error::TooManyResults` is a domain outcome, like `NotFound`: `configuration?`
and `transient?` both false, inherited from the base class. The README's error
table and its remediation example both need it.

### Test data

The cap and the paging boundaries are proved against real seeded rows, not
stubs. Two cohorts join
`spec/support/mssql_integration_seeds/iPM_REPL/PATIENTS.sql`:

- a **paging cohort** of about a dozen patients, enough for several pages at a
  small `per_page`, including a merged pair that collapses across a page edge
- a **cap cohort** of 2001 patients, inserted set-based from a row-numbering
  CTE rather than as 2001 literal tuples, so the file stays readable and
  seeding stays one statement

Both cohorts take surnames and forenames that the existing examples' fragments
cannot reach — `jud`, `pry`, `pr`, `vau`, `e`, `%`, `or` — and dates of birth
outside the ones those examples search, so no existing expectation changes
meaning.

## Out of Scope

- Paging in clinical_exchange — `Patient.search`, `Patient::Results`, the
  controller, and the search view are untouched. That path also has a local
  ActiveRecord fallback which returns a relation, not a `Page`, so giving the
  two a common shape is its own feature.
- Cursor or keyset pagination. Page numbers were asked for; keyset gives no
  total count and no jump-to-page.
- Paging `by_urn` / `by_urn!` — they return at most one record.
- Chunking the batched `IN` lists. The cap keeps every lookup inside one
  statement, so there is nothing to chunk.
- Configurable `MAX_RESULTS`. A constant until something needs otherwise.
- Sort order as a caller argument. Surname then forename stays fixed.

## Open Questions

- Return a `Page` always, or only when paging args are passed? → Always. One
  return type; `Enumerable` keeps existing callers working.
- Cap by raising or by truncating with a flag? → Raise
  `Error::TooManyResults`. A partial count presented as a total misleads.
- Cap measured pre- or post-collapse? → Pre-collapse `COUNT(*)`, cheap and
  knowable before any resolution work.
- Cap enforced by `COUNT(*)` or a `limit(MAX + 1)` probe? → `COUNT(*)`. Costs
  an extra round trip per search, buys an error message naming the real
  figure, which tells the user how much narrowing is needed.
- Can a paginating caller still hit `TooManyResults`? → Yes, and at the
  originally planned cap of 200 that made pagination useless on the searches
  it was for. Resolved by batching resolution first, which lifts the cap to
  2000.
- `MAX_RESULTS` value? → 2000, sized by SQL Server's 2100-parameter statement
  limit.
- Does page 1 of a zero-match search raise? → No. Page 1 is always valid.
- Which queries get paging? → Both `find_all_by` and `matching`.
- Out-of-range: `ArgumentError` or a `Conduit::Error`? → `ArgumentError`,
  consistent with the blank-criteria precedent in `given_criteria`.
- How does a 2001-row cap cohort get past the seeder's own safety guard?
  → `MAX_TEST_TABLE_ROWS` raised from 1000 to 5000. The guard exists to stop
  the seed scripts' `DELETE` reaching production, and it aborts when any
  seeded table is oversized — a real `PATIENTS` holds millions, so it still
  trips on the first table it checks. Shrinking the cohort instead was
  rejected: it would let a test-harness limit decide conduit's public cap.
- Is the existing `merge_resolver_spec` a safety net for the batching slice?
  → Only partly. It stubs `latest_target` and `active_by_refno` per refno, so
  it is coupled to the collaborators being replaced and has to be rewritten
  against the batched ones. The real net is the integration merge coverage in
  `patient_matching_spec` and `ur_search_spec`, which goes through real SQL
  and must pass untouched.

## Slices

### Slice 1: Batch merge resolution

**Commit:** `refactor: resolve merge chains for a whole row set`
**Files:**
- `gems/conduit/lib/conduit/ipm/merge_resolver.rb`
- `gems/conduit/lib/conduit/ipm/relations/merged_patients.rb`
- `gems/conduit/lib/conduit/ipm/relations/patients.rb`
- `gems/conduit/spec/conduit/ipm/merge_resolver_spec.rb`

**Spec:** rewritten against the batched collaborators — a set of rows
resolving in one pass; unmerged rows returned untouched; a chain of more than
one hop followed to the current record; a cycle ending instead of looping; a
row whose current record is archived dropped; rows resolving to one patient
collapsing with the direct hit winning; ordering by surname then forename; the
single-row `resolve` path still answering `by_urn`. Query counts asserted so
the N+1 cannot return: resolving many rows issues a number of queries set by
chain depth, not row count. Integration merge examples must pass unchanged.

**Status:** done

### Slice 2: Page value object

**Commit:** `feat: add a page value object for query results`
**Files:**
- `gems/conduit/lib/conduit/page.rb` (new)
- `gems/conduit/lib/conduit.rb`
- `gems/conduit/spec/conduit/page_spec.rb` (new)

**Spec:** `Page.of` slicing a record set for a given page and size; totals
across the whole set; `current_page`, `next_page`, `previous_page`,
`first_page?` and `last_page?` at both ends and in the middle; a nil
`per_page` holding everything as one page; an empty record set giving
`total_pages` 0 with page 1 valid; `page < 1` and `per_page < 1` raising
`ArgumentError`; a page past the last raising `ArgumentError` naming both
numbers; `Enumerable`, `length` and `empty?` behaving like the array it
replaces.

**Status:** done — a plain class rather than a `Data`, since `Enumerable`
sits ahead of `Data` in the ancestors and shadows `Data#to_h` with a version
that raises on anything but pairs.

### Slice 3: Searches return a page

**Commit:** `feat: return patient searches as a page`
**Files:**
- `gems/conduit/lib/conduit/ipm/repositories/patients.rb`
- `gems/conduit/spec/integration/patient_matching_spec.rb`
- `gems/conduit/README.md`

**Spec:** `find_all_by` and `matching` return a `Page` carrying every match as
one page, with `total_count` matching the record count; existing matching,
merge-collapse, ordering and injection examples reworked off `eq []` onto the
page's own `empty?`; the audit event still identifies collection results by
URN through the Enumerable path.

**Status:** done — `Repository#audited` needed no change after all. It reaches
for `length` and `map`, which `Page` and `Enumerable` already answer, so the
planned switch to `count` was unnecessary.

### Slice 4: Page and per-page arguments

**Commit:** `feat: page through patient search results`
**Files:**
- `gems/conduit/lib/conduit/ipm/repositories/patients.rb`
- `gems/conduit/lib/conduit/repository.rb`
- `gems/conduit/lib/conduit/page.rb`
- `gems/conduit/spec/support/mssql_integration_seeds/iPM_REPL/PATIENTS.sql`
- `gems/conduit/spec/support/mssql_integration_seeds/iPM_REPL/MERGED_PATIENTS.sql`
- `gems/conduit/spec/integration/patient_matching_spec.rb`
- `gems/conduit/README.md`

**Spec:** walking the seeded paging cohort returns each record once, in
surname order, with stable boundaries and no record on two pages;
`total_count` and `total_pages` reflect the whole set from any page; the
cohort's merged pair still collapses to one record across a page edge; `page`
or `per_page` below 1 raises before any query and emits no event; a page past
the last raises `ArgumentError` and leaves an event carrying it; the event's
`params` record the page asked for while `record_ids` names only that page's
records.

**Status:** done — `Page.validate_request!` became public so the repository can
refuse a nonsense request before spending a query, which is what makes the
"leaves no trace" case true. `repository_spec` needed nothing: all three audit
behaviours are provable end to end. The two searches, by then identical bar
their match relation, share a private `paged` helper.

### Slice 5: Cap oversized searches

**Commit:** `feat: reject searches matching too many patients`
**Files:**
- `gems/conduit/lib/conduit/errors.rb`
- `gems/conduit/lib/conduit/ipm/repositories/patients.rb`
- `gems/conduit/spec/support/mssql_integration_seeds/iPM_REPL/PATIENTS.sql`
- `gems/conduit/spec/support/mssql_seed_integration_tests.rb`
- `gems/conduit/spec/conduit/errors_spec.rb`
- `gems/conduit/spec/integration/patient_matching_spec.rb`
- `gems/conduit/README.md`

**Spec:** `TooManyResults` is a `Conduit::Error` that is neither
`configuration?` nor `transient?`; a search across the seeded cap cohort
raises it naming the count, without fetching or resolving the rows; a search
narrowed to just inside the limit returns a page; the refused search leaves an
audit event carrying the error.

**Status:** done — an example also pins the deliberate behaviour that passing
`per_page` does not get around the cap, since that was the design question the
batching slice came out of. The seeder's own row-count guard had to rise to
5000 to admit the cohort.
