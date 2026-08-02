# Feature: Patients Lookup

## Goal
A clinician searches iPM for a patient from Clinical Exchange, selects
one, and that patient is kept locally so the search still works when iPM
is unreachable.

## User Story
As a clinician using Clinical Exchange, I want to look a patient up by
URN or by name and date of birth and select them, so that I can work
with that patient's identity even when the iPM replica is down.

## Acceptance Criteria
- [ ] Every page shows the app sidebar and header
- [ ] A "Patients" item in the sidebar opens the patients page
- [ ] The patients page offers a URN search and an advanced search on
      first name, last name and date of birth
- [ ] Entering fewer than 7 digits in the URN field still finds the
      patient — leading zeros are added
- [ ] Searching an unknown URN reports that no patient was found
- [ ] Submitting an empty advanced search reports that at least one
      criterion is required, and runs no query
- [ ] Search results list each matching patient with name, URN, date of
      birth and gender, and a way to select one
- [ ] Selecting a patient opens that patient's page, showing the patient
      info header
- [ ] A patient selected once is still findable by URN and by name when
      iPM is unreachable
- [ ] When results come from local records instead of iPM, the page says
      so in an alert
- [ ] When iPM is misconfigured or the query fails outright, the page
      reports an error rather than silently showing local results
- [ ] Every conduit query is written to the Rails log
- [ ] No patient identifier reaches a URL, so none reaches the browser
      history or a shared link
- [ ] A burst of searches beyond the cap is refused
- [ ] The request log records a search without its first name or date of
      birth

## Implementation Notes

### Conduit's real API
The gem's README documents a `Conduit::Result` API that does not exist
in the code. The real surface, which this feature codes against:

```ruby
Conduit.ipm.patients.by_urn(urn)        # => Patient | nil
Conduit.ipm.patients.by_urn!(urn)       # raises Error::NotFound
Conduit.ipm.patients.find_all_by(first_name:, last_name:,
                                 date_of_birth:)  # => [Patient]
Conduit.ipm.patients.matching(...)      # => [Patient], fuzzy names
```

Database failures **raise** `Conduit::Error` subclasses; they are not
returned. `Conduit::IPM::Patient` is a `ROM::Struct` with `urn`,
`first_name`, `last_name`, `date_of_birth`, `gender`, `atsi_status`,
`merged_from`, plus `merged?`. Slice 1 corrects the README.

### Decisions taken at intake
- **Local record** — mirrors every conduit attribute, including
  `atsi_status` and `merged_from`. One `patients` table, `urn` unique,
  no owner and no auth. Selecting an already-saved patient refreshes the
  snapshot.
- **Fallback trigger** — `rescue Conduit::Error` and fall back to local
  records only when `error.transient?` (`ConnectionFailed`, `Timeout`).
  `configuration?` errors and `QueryError` re-raise and surface as an
  error state. `NotFound` is a domain outcome, not a fallback.
- **Fallback matching** — mirrors conduit: advanced search matches name
  fragments case-insensitively and date of birth exactly; URN search is
  exact.
- **Where the logic lives** — on the local `Patient` model. `Patient
  .search` queries conduit, handles the fallback, and reports which
  source answered. The controller stays CRUD-thin. No service object.
- **Selection** — `POST /patients` saves the record and redirects to
  `/patients/:urn`, which renders `render_patient_info_header`.
  Selection is a URL, so it survives a reload.
- **Specs** — app specs stub `Conduit.ipm` at the boundary and never
  touch MSSQL; conduit's own suite covers the SQL. Stubs return real
  `Conduit::IPM::Patient` structs and raise real `Conduit::Error`
  subclasses.
- **Audit** — `Conduit.on_query` subscriber logging via `Rails.logger`.
  No table, no user context; the app has no authentication yet.
- **Credentials** — per-environment Rails credentials, each with its own
  key: `config/credentials/development.yml.enc`, `test.yml.enc` and
  `production.yml.enc`, holding `conduit.ipm.username` / `password`.
  Development and test carry dummy values for the local MSSQL container;
  production carries the real SELECT-only login. CI decrypts with a
  `RAILS_MASTER_KEY` secret holding the *test* key — Rails falls back to
  that variable for whichever environment file is active. The existing
  `config/credentials.yml.enc` has no key and no reader once the
  per-environment files exist.
- **Chrome** — sidebar and header move into the application layout,
  copying the wiring in gesso's dummy `layouts/main.html.erb`.

### Keeping identifiers out of URLs

Slice 7 shipped the search as `GET /patients?urn=0700003`. That puts a
patient identifier in the address bar, the browser history, the access
log and any `Referer` header, and it lets another origin trigger a
search in a clinician's session with an `<img>` tag. Slice 8 replaces it:

- The search **posts**, so criteria travel in the body. Rails' forgery
  protection then applies, which is what stops a cross-origin page
  driving searches under someone's session.
- The response comes back inside a **turbo frame**, so the results swap
  in without a redirect and the URL stays `/patients`.
- Local patients are keyed by **UUIDv7**, generated by Postgres 18's
  native `uuidv7()` — no extension. The patient page is then
  `/patients/019fc039-…` rather than `/patients/0700003`. New tables get
  the same default. Note a v7 UUID encodes its creation time; it is
  unguessable, not opaque.
- `first_name` and `date_of_birth` are filtered from the request log.
  The URN stays, and conduit's audit line is left complete — recording
  what was actually searched is the point of the trail.
- The search action is **rate limited**, which is the only one of these
  that blunts scripted enumeration.

What none of this does: stop an authorised user from enumerating URNs.
CSRF fails the moment the attacker can read the token, which anyone who
can load the page can. Rate limiting keyed on a session is sidestepped
by clearing cookies. The real controls are authentication and an
attributable audit trail, and this app has neither yet — see *Out of
scope*. The URN itself is iPM's identifier and cannot be made secret.

## Out of Scope
- Authentication, users, and per-user patient ownership — until it
  exists, searches are anonymous, the audit trail names nobody, and the
  rate limit can only key on a session
- Attributing conduit's audit events to the user who caused them
- Phone number search — conduit exposes no phone column or query
- Persisting the audit trail to a table
- Any write back to iPM; conduit is read-only
- A patients index or list of saved patients — the local table is
  reached only through search and the show page
- Editing or deleting a locally saved patient
- Pagination of search results

## Open Questions
- Conduit needs `CONDUIT_MSSQL_HOST`, `CONDUIT_MSSQL_PORT` and
  `CONDUIT_IPM_DATABASE` outside development and test, or it fails at
  boot → unresolved; needed before deploy, not before any slice.
- Whether CI needs a real iPM to be reachable → resolved: no. App specs
  stub conduit; the workflow gets dummy credentials only.
- Audit events record patient names and dates of birth in `params`. The
  Rails log therefore becomes patient-identifying → accepted for now,
  revisit when the trail is persisted.

## Slices

### Slice 1: Correct conduit's documented API
**Commit:** `docs: correct conduit's documented query API`
**Files:** `gems/conduit/README.md`
**Spec:** none — documentation only. Verified by reading the code paths
it describes: `Conduit.ipm`, `Repositories::Patients`, `Repository#
guarded`, `IPM::Patient`.
**Status:** done

### Slice 2: Configure conduit in the app
**Commit:** `feat: configure conduit in clinical exchange`
**Prerequisite (you run these):** in `apps/clinical_exchange`, one per
environment —
`bin/rails credentials:edit --environment development`, `--environment
test`, `--environment production` — each holding

```yaml
conduit:
  ipm:
    username: <login>
    password: <password>
```

then add `RAILS_MASTER_KEY` as a GitHub Actions secret holding the
contents of `config/credentials/test.key`.
**Files:** `apps/clinical_exchange/Gemfile`, `Gemfile.lock`,
`config/initializers/conduit.rb`,
`config/credentials/{development,test,production}.yml.enc`,
`.github/workflows/clinical_exchange.yml`, `README.md`,
`spec/initializers/conduit_spec.rb`
**Spec:** conduit is configured with the application name and the ipm
source; a `query.conduit` event is written to the Rails log.
**Note:** the README documents the conduit variables a deployed
environment must supply — `CONDUIT_MSSQL_HOST`, `CONDUIT_MSSQL_PORT`,
`CONDUIT_IPM_DATABASE`.
**Status:** done

### Slice 3: Put the chrome in the layout
**Commit:** `feat: add sidebar and header to the layout`
**Files:** `app/views/layouts/application.html.erb`,
`app/views/static_pages/home.html.erb`, `spec/system/home_spec.rb`
**Spec:** every page renders the sidebar and header; the home page no
longer renders a header of its own. Nav holds Dashboard only — the
Patients item arrives with the route in slice 7.
**Status:** done

### Slice 4: Local patient records
**Commit:** `feat: add local patient records`
**Files:** `db/migrate/<ts>_create_patients.rb`, `db/schema.rb`,
`app/models/patient.rb`, `spec/models/patient_spec.rb`,
`spec/factories/patients.rb`
**Spec:** `Patient.remember` keeps a `Conduit::IPM::Patient`, upserting on
URN so a second selection refreshes the snapshot; URN is unique in the
database.
**Status:** done

### Slice 5: Local patient search
**Commit:** `feat: add local patient search`
**Files:** `app/models/patient.rb`, `spec/models/patient_spec.rb`
**Spec:** scopes find a saved patient by exact URN, by name fragment
case-insensitively, and by exact date of birth; blank criteria raise
rather than returning the whole table.
**Status:** done

### Slice 6: Search conduit, fall back locally
**Commit:** `feat: search patients through conduit`
**Files:** `app/models/patient.rb`, `app/models/patient/results.rb`,
`spec/models/patient_spec.rb`
**Spec:** `Patient.search` returns conduit records and reports iPM as
the source; a URN shorter than 7 digits is zero-padded; a transient
conduit error falls back to local records and reports the local source;
a configuration error and a `QueryError` propagate; an unknown URN
returns no records without falling back.
**Status:** done

### Slice 7: The patients page with URN search
**Commit:** `feat: add the patients page with URN search`
**Files:** `config/routes.rb`, `app/controllers/patients_controller.rb`,
`app/views/patients/index.html.erb`,
`app/views/layouts/application.html.erb` (nav item),
`app/helpers/patients_helper.rb`, `spec/requests/patients_spec.rb`,
`spec/requests/chrome_spec.rb`
**Spec:** the page renders the URN search; a URN search lists the
matching patient; an unknown URN reports that nothing was found; the
sidebar links to the page. The search tabs arrive with slice 8, when
there is a second search to switch to.
**Status:** done

### Slice 8: Post the search inside a turbo frame
**Commit:** `feat: post the patient search`
**Files:** `config/routes.rb`,
`app/controllers/patients/searches_controller.rb`,
`app/views/patients/index.html.erb`,
`app/views/patients/searches/{_search,create}.html.erb`,
`app/controllers/patients_controller.rb`,
`spec/requests/patients/searches_spec.rb`,
`spec/requests/patients_spec.rb`, `spec/system/patients_spec.rb`
**Spec:** the search posts and swaps the results into the frame without
changing the URL; a URN search lists the matching patient; an unknown
URN reports that nothing was found; the search page carries no
identifier in its URL.
**Status:** done

### Slice 9: Key records by UUIDv7
**Commit:** `feat: key patients by uuid`
**Files:** `db/migrate/<ts>_change_patients_primary_key_to_uuid.rb`,
`db/schema.rb`, `config/initializers/generators.rb`,
`spec/models/patient_spec.rb`, `spec/initializers/generators_spec.rb`,
`README.md`, `.claude/rails/models.md`
**Spec:** a saved patient has a version 7 UUID for its id, generated by
the database; the patients key defaults to `uuidv7()`; the generators
produce uuid keys.
**Note:** Rails hard-codes `gen_random_uuid()` (version 4) for uuid
primary keys and has no knowledge of `uuidv7()`, so the generator option
gives the uuid *type* only — every migration names the function itself.
An initializer patching the adapter to do this automatically was written
and then dropped: overriding a Rails internal that can move under us was
judged worse than an explicit line per migration. The requirement is
documented in the README and the model guidelines instead, since nothing
fails when it is forgotten — the ids are simply version 4.
**Status:** done

### Slice 10: Rate limit the search
**Commit:** `feat: rate limit patient searches`
**Files:** `app/controllers/patients/searches_controller.rb`,
`app/views/patients/searches/{_search,create}.html.erb`,
`config/environments/test.rb`,
`spec/requests/patients/searches_spec.rb`
**Spec:** a burst of searches beyond the cap is refused with an alert
and 429; searching up to the cap is unaffected.
**Note:** 20 searches a minute, keyed on the requesting address, since
there is no user to key on yet. The test environment's `:null_store`
discards the counter, so the limit could never fire under test — test
now uses `:memory_store`, and the throttle examples clear the cache
either side of themselves so the shared counter cannot leak into other
examples.
**Status:** done

### Slice 11: Keep criteria out of the request log
**Commit:** `chore: filter patient criteria from the request log`
**Files:** `config/initializers/filter_parameter_logging.rb`,
`spec/requests/patients/searches_spec.rb`
**Spec:** a search's first name and date of birth are filtered from the
logged parameters; the URN is not.
**Note:** asserted through `request.filtered_parameters`, which is what
Rails writes to the log. Filtering is a partial match, so a later
`date_of_birth_day` field is covered too.
**Status:** done

### Slice 12: Advanced search
**Commit:** `feat: add advanced patient search`
**Files:** `app/controllers/patients/searches_controller.rb`,
`app/views/patients/index.html.erb`,
`app/views/patients/{_urn_search,_advanced_search}.html.erb`,
`app/views/patients/searches/{_results,create}.html.erb`,
`spec/requests/patients/searches_spec.rb`,
`spec/requests/patients_spec.rb`, `spec/system/patients_spec.rb`
**Spec:** name and date-of-birth criteria list matching patients; a
single criterion is enough; an empty search asks for one and runs no
query; an unreadable date of birth is named rather than searched for;
searching from the advanced tab leaves the clinician on it.
**Note:** the turbo frame shrank to the results region and both forms
target it. `render_tabs` always selects the first tab, so swapping the
whole page region would have thrown the clinician back to the URN tab
with their criteria gone — changing gesso was the alternative. The
partial `patients/searches/_search` became `_results`.
**Status:** done

### Slice 13: Select and save a patient
**Commit:** `feat: save a selected patient locally`
**Files:** `config/routes.rb`, `app/controllers/patients_controller.rb`,
`app/views/patients/index.html.erb`,
`app/views/patients/show.html.erb`, `spec/requests/patients_spec.rb`
**Spec:** selecting a result saves the patient locally and redirects to
its page, addressed by UUID, which shows the patient info header;
selecting the same patient twice keeps one record.
**Status:** pending

### Slice 14: Say when results are local
**Commit:** `feat: flag results served from local records`
**Brought forward** to follow slice 8 — it completes the search surface
and depends on nothing later.
**Files:** `app/controllers/patients/searches_controller.rb`,
`app/views/patients/searches/{_search,create}.html.erb`,
`spec/requests/patients/searches_spec.rb`, `spec/system/patients_spec.rb`
**Spec:** a fallback search renders a warning alert naming iPM as
unavailable and the results as previously kept; an iPM-served search
renders no alert; a fallback that matches nothing says no *saved*
patient matches rather than claiming the patient does not exist; a
configuration failure renders a critical alert instead of results.
**Status:** done

### Slice 15: End-to-end cover
**Commit:** `test: cover the patients lookup end to end`
**Files:** `spec/system/patients_spec.rb`
**Spec:** a clinician opens Patients from the sidebar, searches a URN,
selects the patient, and lands on the patient page; with iPM down, the
same patient is found again from local records with the fallback alert
shown. The search half landed with slice 8.
**Status:** pending
