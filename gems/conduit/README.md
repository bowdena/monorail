# Conduit

This gem is built to use hanakai's ROM gem 
(https://hanakai.org/learn/rom/v5.0/getting-started) as a repository pattern for 
data access into readonly data sources.  The general vision for this gem is
that the gem contains the abstraction about the database structure and 
shape of the data.  The gem responds with a data structure to add a public
API for accessing the data and restricts the calling systems knowledge of the 
internals.

The gem does not require active record and is written to maintain 
compatibility with Ruby.


## Installing

Conduit is a path gem, consumed the same way as gesso:

```ruby
# apps/<app>/Gemfile
gem "conduit", path: "../../gems/conduit"
```

## Configuring

Apps configure identity only: their application name and their own
SELECT-only credentials for each source they use. Server locations
are conduit's concern, never the app's.

```ruby
# config/initializers/conduit.rb
Conduit.configure do |config|
  config.application = "app_one"

  config.source :ipm,
    username: ENV["CONDUIT_IPM_USERNAME"],
    password: ENV["CONDUIT_IPM_PASSWORD"]
end
```

Configure only the sources you use. Querying an unconfigured source
returns a failed `Result` with `Error::NotConfigured`.

The valid source names are discoverable at runtime — configuring
anything else raises at boot, naming this list:

```ruby
Conduit.sources  # => [:ipm]
```

### Where the server lives: two regimes

One MSSQL instance hosts a database per source.

- **development / test** — conduit defaults to a local instance on
  `localhost:1433` with an `iPM_REPL` database, zero configuration.
  The spec suite seeds the databases it needs.
- **every other environment** — no defaults exist. The instance
  location must come from conduit-owned variables
  (`CONDUIT_MSSQL_HOST`, `CONDUIT_MSSQL_PORT`) plus a database name
  per source (`CONDUIT_IPM_DATABASE`). A missing variable fails at
  boot with `Error::NotConfigured` — a production deploy can never
  silently connect to `localhost`.

## Querying

Named queries only; each returns a `Conduit::Result` and never
raises on database failure.

```ruby
result = Conduit::IPM::Patients.find_by_urn(urn: "0700003")
result = Conduit::IPM::Patients.find_all_by(
  first_name: "Tori", last_name: "Judd",
  date_of_birth: Date.new(1957, 9, 29)
)
result = Conduit::IPM::Patients.matching(last_name: "jud")
```

- `find_by_urn` — one patient by URN; fails with `Error::NotFound`
  when nothing matches.
- `find_all_by` — exact, case-insensitive name matching (any subset
  of first name, last name, date of birth); succeeds with `[]` when
  nothing matches.
- `matching` — like `find_all_by`, but names match on any fragment.
  Date of birth stays exact — a fuzzy date has no meaning.

`find_all_by` and `matching` raise `ArgumentError` when every
criterion is blank: matching the entire table is a caller bug, not a
query.

```ruby
if result.success?
  result.records  # frozen Data rows (Conduit::IPM::Patient)
  result.record   # first record, for single-row queries
else
  result.error    # a Conduit::Error subclass — see below
end
```

### Merge resolution is always on

iPM merges duplicate patient records; the replica keeps the trail in
`MERGED_PATIENTS`. Every query follows that chain to the current
record — searching a merged-away URN returns the patient it merged
into, and rows resolving to the same patient collapse to one record.
When resolution crossed a merge, `merged_from` on the returned
record carries the searched or matched URN, so a caller can never
mistake merge resolution for a wrong result.

Need data conduit doesn't expose? Add a named query to the relevant
resource in this gem — apps never reach past the public API.

## Record shapes

Every row is a frozen Ruby `Data` value — plain attributes, no
ActiveRecord, no lazy loading, safe to pass around and cache.

| Type                    | Attributes                                 |
|-------------------------|--------------------------------------------|
| `Conduit::IPM::Patient` | `urn`, `first_name`, `last_name`,          |
|                         | `date_of_birth`, `gender`, `atsi_status`,  |
|                         | `merged_from` (searched URN when           |
|                         | resolution crossed a merge, else nil)      |

Internal keys never leak: patients expose the URN (iPM's `PASID`),
not the replica's `PATNT_REFNO` primary key, and reference codes
arrive as their descriptions (`gender`, `atsi_status`).

The shapes are also discoverable at runtime, since `Data` classes
describe themselves:

```ruby
Conduit::IPM::Patient.members
# => [:urn, :first_name, :last_name, :date_of_birth, :gender,
#     :atsi_status, :merged_from]

result.record.to_h   # attribute => value hash for a fetched record
```

`members` is the contract — if a column is added to a source, it only
reaches apps when the Data type and its mapping grow to include it.

## Errors

Every failure is a typed error on `result.error`, carrying `message`,
`source` (which database was involved) and `cause` (the underlying
adapter exception, when there is one).

| Error                         | Meaning                                 |
|-------------------------------|-----------------------------------------|
| `Error::NotConfigured`        | source not configured in this app       |
| `Error::AuthenticationFailed` | login rejected — credentials are wrong  |
| `Error::PermissionDenied`     | grant or database missing for the login |
| `Error::ConnectionFailed`     | server unreachable / down               |
| `Error::Timeout`              | connect or statement took too long      |
| `Error::NotFound`             | `find` matched no row                   |
| `Error::QueryError`           | statement failed; also the catch-all    |

Rather than listing classes, branch on the remediation predicates:

```ruby
case
when result.error.configuration?
  # NotConfigured, AuthenticationFailed, PermissionDenied — a human
  # must fix settings or provisioning; alert loudly.
when result.error.transient?
  # ConnectionFailed, Timeout — retrying later may succeed; degrade
  # gracefully.
else
  # NotFound is a domain outcome; QueryError is a conduit bug —
  # report it.
end
```

## Audit trail

Conduit emits a `query.conduit` event for every query — guard
failures included, so even a misconfigured app leaves a trace.
Subscribe once in an initializer with `Conduit.on_query`, which
yields a typed `Conduit::QueryEvent`.

Subscribers run synchronously in the calling thread. That is the
contract that lets your app attach its own user context: conduit
carries no user plumbing, so recording *who* asked is the consuming
app's responsibility — an app without a subscriber has no trail.

```ruby
# config/initializers/conduit.rb
Conduit.on_query do |query|
  AuditEntry.create!(user: Current.user&.username, **query.to_h)
end

# or, logging instead of persisting:
Conduit.on_query do |query|
  Rails.logger.info(
    "[conduit] #{query.to_h.merge(user: Current.user&.username)}"
  )
end
```

`query.to_h` has exactly nine keys: `application`, `source`,
`resource`, `name`, `params`, `duration` (ms), `row_count`,
`record_ids`, `error` (class name or nil). `record_ids` identifies
returned rows by URN; a merge-resolved query runs several statements
but emits one event, identifying the record actually returned.

Know what the event carries before choosing where to store it:
`params` records the search criteria verbatim — for the name
searches that includes a patient's name and date of birth, which is
the point of an audit trail but makes the store patient-identifying.
Returned rows appear only as URNs; row data (the matched records'
attributes) never enters an event.

`on_query` returns the subscription; pass it to
`ActiveSupport::Notifications.unsubscribe` if you need teardown (test
suites do).

## Developing conduit itself

Two spec tiers:

- `spec/conduit/**` — unit specs, no database. `bundle exec rspec`.
- `spec/integration/**` — run against an external MSSQL instance
  that the suite seeds itself:

```sh
bundle exec rspec                       # everything
CONDUIT_SKIP_MSSQL=1 bundle exec rspec  # unit specs only
```

Integration specs run by default. Start the local Docker instance
with `mise run mssql:up` (`mise run mssql:down` to stop it). To
point the specs at another instance instead, set CONDUIT_MSSQL_HOST
and CONDUIT_MSSQL_PORT.

The layout of `spec/support/mssql_integration_seeds/` is part of the
seeder's API: directory names are database names, `database.sql`
bootstraps, and every other file is named exactly as the one table
it seeds. The seeder derives its scripts — and the safety guard that
refuses to touch a real-looking instance — from those names, so a
misnamed file escapes the guard. Details in
`spec/support/mssql_seed_integration_tests.rb`.
