# Feature: Clinical Exchange search pagination

## Goal

A clinician whose search matches more patients than fit on a screen sees the
first 25 and can step through the rest.

## User Story

As a clinician searching for a patient, I want a long list of matches broken
into pages I can step through, so that I can find the right patient without
scrolling past a hundred rows or being told to search again.

## Acceptance Criteria

- [ ] A search matching more than 25 patients shows the first 25 and
      pagination controls
- [ ] The controls say which page is current, and offer previous and next
      where they exist
- [ ] Choosing a page shows that page's patients without losing the search
      criteria or the tab the clinician searched from
- [ ] A search matching 25 or fewer shows no pagination controls
- [ ] Paging works the same when iPM is unreachable and the search falls back
      to patients kept locally
- [ ] Selecting a patient from any page still opens that patient
- [ ] A page link from an older search whose results have since shrunk shows
      the first page and says why
- [ ] A search too broad for conduit to serve tells the clinician to narrow
      it, and says how many matched — not that it needs reporting
- [ ] A patient's first name and date of birth stay out of the request log

## Implementation Notes

### The name search moves to GET; the urn search does not

Pagination controls are links, so the search they page has to be reachable by
one. The route becomes `resource :search, only: %i[ create show ]` — one
path, the verb choosing between them — and only the advanced form gains
`method: :get`.

The split came from an existing spec, `searches_spec.rb` "keeps the urn out
of the response url", which pinned a deliberate decision that criteria stay
out of the URL. A urn search matches at most one patient and never needs a
page, so it keeps its POST and that spec keeps its meaning. Only the name
search, which is the one that can match more than a screenful, pays the cost.

That cost was weighed and accepted for the name search: its criteria travel
in the query string, so they reach access logs and any `Referer` sent onward.
They do not reach the address bar in the ordinary flow — the form targets a
turbo frame, and Turbo leaves the browser URL alone on a frame navigation
unless the frame opts in with `data-turbo-action="advance"`.

The namespace has to be declared before `resources :patients`: `patients#show`
answers `GET /patients/:id`, which otherwise swallows `/patients/search` as a
patient whose id is "search".

### Logging is already handled, and deliberately partial

`config/initializers/filter_parameter_logging.rb` already filters
`first_name` and `date_of_birth`, with a comment explaining the reasoning:
the URN is what staff quote to each other and a log without it is far less
useful, while a name and date of birth together identify someone. Rails
filters query strings as well as bodies — `Rails::Rack::Logger` logs
`request.filtered_path` — so moving to GET needs no change here.

Left as it stands. Adding `last_name` is a one-line change if the surname
appearing in access logs is judged differently now that it also appears in
URLs and browser history.

### Pagination is conduit's, presented by gesso

`Conduit::Page` already does the paging: `current_page`, `per_page`,
`total_count`, `total_pages`, `next_page`, `previous_page`, `first_page?`,
`last_page?`. Nothing here recomputes any of it.

`render_pagination(pages:, previous:, next_page:)` renders a *precomputed*
window — gesso's partial documents that the caller does the page maths and
hands in `{ number:, path:, current: }` entries plus `:gap` symbols. So a
`PatientsHelper` method turns a page and the current criteria into that
window. Gesso is not changed.

### Both search paths paginate

`Patient::Results` grows `current_page`, `per_page` and `total_count`, filled
from conduit's `Page` on the iPM path and from `offset`/`limit` plus a
`count` on the local ActiveRecord fallback. One shape, one view path, so a
clinician who loses iPM mid-session keeps the controls they were using.

`Patient.remembered` reads `search(urn:).records.first` and must keep
working: a URN search returns at most one record, so it sits on page 1
regardless.

### Errors the pagination introduces

A bookmarked page 5 of a search now returning 3 pages raises `ArgumentError`
from conduit. Rescued, re-run at page 1, with an alert saying the results
have changed — a clinician following an old link should still get their
search.

`Error::TooManyResults` currently falls into the `Conduit::Error` rescue and
renders "report it rather than retrying", which is wrong: it is
user-correctable and paging cannot fix it, since conduit resolves the whole
match set before cutting a page. It gets its own alert naming the count and
asking for a narrower search.

### Page size

`RESULTS_PER_PAGE = 25` on the controller. No per-page control.

## Manual testing

Development conduit points at the local `iPM_REPL`, which the conduit gem's
spec suite seeds. Two cohorts are there for this:

| Search | What it proves |
|--------------------------|--------------------------------------|
| Last name **Quinn** | 12 patients (`Ann01 Quinn` … `Ann12 Quinn`, all born 08/03/1966), so 25 per page is one page — drop `RESULTS_PER_PAGE` to 5 to see three pages |
| Last name **Kwok** | 2001 patients, one past conduit's cap, so the "too many" alert |
| Last name **Judd** | one patient (`Tori Judd`, 29/09/1957), the no-pagination case |

The cohorts are spec fixtures, not development seeds: they are present
because the conduit suite seeded them. A fresh `mise run mssql:up` will not
have them until that suite runs again.

## Out of Scope

- A per-page control. 25 is fixed.
- Sorting. Conduit orders by surname then forename and takes no argument.
- Paging anything other than patient search.
- Changing gesso. Its pagination component already does what is needed.
- Cursor pagination or infinite scroll.
- Filtering `last_name` from logs — see above; the existing policy stands
  unless revisited.

## Open Questions

- How is page 2 requested, given search was a POST? → Search moves to GET.
  Criteria in the URL was weighed against browser history, access logs and
  `Referer`, and accepted.
- Does the local fallback paginate too? → Yes. `Patient::Results` carries the
  paging for both paths.
- Is `TooManyResults` fixed here? → Yes. It reads as an outage today.
- Page size? → 25, fixed.
- What does a stale page link show? → Page 1, with a notice.
- Does GET need new log filtering? → No. `first_name` and `date_of_birth` are
  already filtered and Rails filters query strings. Whether `last_name`
  should join them is a live question, deliberately left alone.
- Can the app suite run? → Yes. Postgres runs on port 5510 under mise, per
  `apps/clinical_exchange/mise.toml`. A shell that has not activated mise for
  that directory defaults to 5432 and fails with `PG::ConnectionBad`, so
  commands need the environment supplied:
  `PGPORT=5510 PGUSER=postgres PGPASSWORD=postgres bin/rails spec`.
  Baseline before this feature: 81 examples, 0 failures.

## Slices

### Slice 1: Search over GET

**Commit:** `refactor: search for patients over GET`
**Files:**
- `apps/clinical_exchange/config/routes.rb`
- `apps/clinical_exchange/app/controllers/patients/searches_controller.rb`
- `apps/clinical_exchange/app/views/patients/_urn_search.html.erb`
- `apps/clinical_exchange/app/views/patients/_advanced_search.html.erb`
- `apps/clinical_exchange/app/views/patients/searches/show.html.erb`
  (renamed from `create.html.erb`)
- `apps/clinical_exchange/spec/requests/patients/searches_spec.rb`
- `apps/clinical_exchange/spec/system/patients_spec.rb`

**Spec:** searching by name over GET returns the same results into the same
turbo frame; the urn search stays a POST and keeps the identifier out of the
url; the log shows the first name and date of birth as filtered in the query
string as well as the params; rate limiting still refuses a flood; an empty
search, an unreadable date, and an unreachable iPM all still render what they
did. No pagination yet — this slice only changes how the search is reached.

**Status:** done — the urn search kept its POST rather than both forms moving,
so the existing "keeps the urn out of the response url" spec stays true. The
search namespace had to move above `resources :patients` to stop
`GET /patients/:id` claiming `/patients/search`.

### Slice 2: Page the results

**Commit:** `feat: page through patient search results`
**Files:**
- `apps/clinical_exchange/app/models/patient.rb`
- `apps/clinical_exchange/app/models/patient/results.rb`
- `apps/clinical_exchange/app/controllers/patients/searches_controller.rb`
- `apps/clinical_exchange/app/helpers/patients_helper.rb`
- `apps/clinical_exchange/app/views/patients/searches/_results.html.erb`
- `apps/clinical_exchange/spec/models/patient_spec.rb`
- `apps/clinical_exchange/spec/requests/patients/searches_spec.rb`
- `apps/clinical_exchange/spec/system/patients_spec.rb`

**Spec:** a search matching more than 25 shows 25 and the controls; 25 or
fewer shows no controls; choosing page 2 shows the next 25 with the criteria
intact; the window helper marks the current page and inserts gaps for a long
run of pages; the local fallback pages the same way; selecting a patient from
page 2 still opens them.

One slice rather than two: paging the model without the controls would ship a
search that silently drops results.

**Status:** done — the local fallback gained an explicit order as well as
offset and limit; a paged query without one lets the database repeat a row on
one page and skip it on another. `params[:page]` is floored at 1 here, so a
hand-edited page of 0 reads as the beginning rather than raising before slice
3 lands. `Patient::Results` restates conduit's page maths rather than wrapping
a `Conduit::Page`, because the local path counts and slices in SQL instead of
handing over every row it matched.

### Slice 3: Stale page links land on page 1

**Commit:** `fix: fall back to page one for a stale page link`
**Files:**
- `apps/clinical_exchange/app/controllers/patients/searches_controller.rb`
- `apps/clinical_exchange/app/views/patients/searches/_results.html.erb`
- `apps/clinical_exchange/spec/requests/patients/searches_spec.rb`

**Spec:** a page past the last renders page 1 with an alert saying the
results have changed; the locally kept records behave the same way; page 1 of
a search matching nothing is not treated as stale; a page below 1 shows the
first page without a notice.

**Status:** done — a page below 1 gets no notice after all. Slice 2 already
floors it to 1, and it only ever arrives from a hand-edited url, so "those
results have changed" would be untrue. The two sources needed handling
separately: conduit raises for a page past the last, while a slice past the
end of the local table is simply empty. `Patient.search` now guarantees the
page it returns exists, and the controller compares that against the page
asked for rather than `Results` carrying a flag.

### Slice 4: Too broad a search asks for narrowing

**Commit:** `fix: tell a clinician to narrow a huge search`
**Files:**
- `apps/clinical_exchange/app/controllers/patients/searches_controller.rb`
- `apps/clinical_exchange/app/views/patients/searches/_results.html.erb`
- `apps/clinical_exchange/spec/requests/patients/searches_spec.rb`

**Spec:** a search conduit refuses for matching too many renders its own
alert naming the count and asking for more detail, not the "report this"
failure alert; a search that fails for any other conduit reason still renders
the failure alert.

**Status:** pending
