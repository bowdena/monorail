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

Configure only the sources you use. Reaching an unconfigured source
raises `Error::NotConfigured` — before a gateway is opened, so a
misconfigured app cannot connect at all.

The valid source names are discoverable at runtime — configuring
anything else raises at boot, naming this list:

```ruby
Conduit.sources  # => [:ipm]
```

### Where the server lives: two regimes

One MSSQL instance hosts a database per source.

- **development** — conduit defaults to a local instance on
  `localhost:1433` with an `iPM_REPL` database, zero configuration.
  This gem's own spec suite runs in this regime and seeds the
  databases it needs.
- **every other environment, test included** — no defaults exist.
  The instance location must come from conduit-owned variables
  (`CONDUIT_MSSQL_HOST`, `CONDUIT_MSSQL_PORT`) plus a database name
  per source (`CONDUIT_IPM_DATABASE`). A missing variable fails at
  boot with `Error::NotConfigured` — a production deploy can never
  silently connect to `localhost`, and neither can a consuming
  application's test suite.

A consuming application should stub conduit at `Conduit.ipm` in its
specs and point these variables at an address that cannot resolve, so
a forgotten stub fails rather than reaching a real instance.

## Querying

Named queries only, reached through the repositories for a source.
`Conduit.ipm` is the entry point; each query returns records, or
raises a typed `Conduit::Error` when the database fails.

```ruby
patients = Conduit.ipm.patients

patients.by_urn("0700003")   # => Conduit::IPM::Patient, or nil
patients.by_urn!("0700003")  # => Patient; raises Error::NotFound
patients.find_all_by(
  first_name: "Tori", last_name: "Judd",
  date_of_birth: Date.new(1957, 9, 29)
)                                    # => [Patient]
patients.matching(last_name: "jud")  # => [Patient]
```

- `by_urn` — one patient by that exact URN, or `nil` when nothing
  matches. URNs are matched as stored: a caller that abbreviates them
  pads to the stored width itself. `by_urn!` raises `Error::NotFound`
  rather than returning `nil`.
- `find_all_by` — exact, case-insensitive name matching (any subset
  of first name, last name, date of birth); `[]` when nothing
  matches.
- `matching` — like `find_all_by`, but names match on any fragment.
  Date of birth stays exact — a fuzzy date has no meaning.

Archived patients are never returned.

`find_all_by` and `matching` raise `ArgumentError` when every
criterion is blank: matching the entire table is a caller bug, not a
query.

Failures are raised, not returned, so a caller that must degrade
rather than fail rescues them:

```ruby
begin
  patients.matching(last_name: "jud")
rescue Conduit::Error => error
  raise unless error.transient?
  # server unreachable or timed out — fall back to something local
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

Every row is a `ROM::Struct` value — plain attributes, no
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

The shapes are also discoverable at runtime, since struct classes
describe themselves:

```ruby
Conduit::IPM::Patient.attribute_names
# => [:urn, :first_name, :last_name, :date_of_birth, :gender,
#     :atsi_status, :merged_from]

record.to_h      # attribute => value hash for a fetched record
record.merged?   # true when merge resolution moved the record
```

`attribute_names` is the contract — if a column is added to a source,
it only reaches apps when the struct and its mapping grow to include
it.

## Errors

Every failure is a typed `Conduit::Error` subclass, carrying
`message`, `source` (which database was involved) and `cause` (the
underlying adapter exception, when there is one). Failures that are
not database failures — a bug in this gem, say — are left alone
rather than dressed up as infrastructure errors.

| Error                         | Meaning                                 |
|-------------------------------|-----------------------------------------|
| `Error::NotConfigured`        | source not configured in this app       |
| `Error::AuthenticationFailed` | login rejected — credentials are wrong  |
| `Error::PermissionDenied`     | grant or database missing for the login |
| `Error::ConnectionFailed`     | server unreachable / down               |
| `Error::Timeout`              | connect or statement took too long      |
| `Error::NotFound`             | a bang query matched no row             |
| `Error::QueryError`           | statement failed; also the catch-all    |

Rather than listing classes, branch on the remediation predicates:

```ruby
begin
  Conduit.ipm.patients.by_urn!(urn)
rescue Conduit::Error => error
  case
  when error.configuration?
    # NotConfigured, AuthenticationFailed, PermissionDenied — a human
    # must fix settings or provisioning; alert loudly.
  when error.transient?
    # ConnectionFailed, Timeout — retrying later may succeed; degrade
    # gracefully.
  else
    # NotFound is a domain outcome; QueryError is a conduit bug —
    # report it.
  end
end
```

## Audit trail

Conduit emits a `query.conduit` event for every query that reaches a
repository, failures included — a rejected login or a missing grant
leaves a trace carrying its error. An unconfigured source is the one
gap: `Conduit.ipm` raises before any query runs, so nothing is
emitted. Subscribe once in an initializer with `Conduit.on_query`,
which yields a typed `Conduit::QueryEvent`.

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
