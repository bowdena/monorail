# Seeds the external MSSQL test instance before any :mssql example
# runs. The seed SQL lives in spec/support/mssql_integration_seeds,
# one directory per database named exactly as the database it
# creates: database.sql (database, login, grants) runs first, then
# one file per table, in sorted order — so a table must sort after
# any table it depends on. All scripts are idempotent; the instance
# is located via Conduit::Sources (built-in test defaults, or the
# CONDUIT_MSSQL_* variables) and seeded with an admin login. Before
# any script runs, every seeded table is checked for a test-sized
# row count — a misconfigured location pointing at a real instance
# aborts the run without executing a single statement. Start a local
# instance with `mise run mssql:up`, point CONDUIT_MSSQL_HOST and
# CONDUIT_MSSQL_PORT at another one, or skip these specs entirely
# with CONDUIT_SKIP_MSSQL=1.
require "tiny_tds"

module ConduitSpec
  module Seeder
    extend self

    SEEDS_ROOT = File.expand_path("mssql_integration_seeds", __dir__)

    # No seed leaves a table anywhere near this many rows; a real
    # database's tables are orders of magnitude past it.
    MAX_TEST_TABLE_ROWS = 1000

    def seed!
      location = Conduit::Sources.location
      client = connect(location)
      ensure_test_instance! client, location
      Conduit::Sources.names.each do |source|
        scripts(source).each do |script|
          batches(script).each { |sql| client.execute(sql).do }
        end
      end
    rescue TinyTds::Error => error
      abort unavailable_message(location, error)
    ensure
      client&.close
    end

    private

    def connect(location)
      TinyTds::Client.new(
        host: location[:host],
        port: location[:port],
        username: ENV.fetch("CONDUIT_TEST_ADMIN_USERNAME", "sa"),
        password: ENV.fetch(
          "CONDUIT_TEST_ADMIN_PASSWORD", "Your_strong_Passw0rd"
        ),
        login_timeout: 5,
        timeout: 30
      )
    end

    # The scripts reset whatever they find — DELETE and reinsert,
    # login password resets — so a location misconfigured to a
    # real instance must stop the run before anything executes.
    # Every table file is named after the table it seeds, which
    # lets the check sweep all of them up front.
    def ensure_test_instance!(client, location)
      oversized = seeded_tables.select do |database, table|
        row_count(client, database, table) > MAX_TEST_TABLE_ROWS
      end

      abort real_instance_message(location, oversized) if oversized.any?
    end

    def seeded_tables
      Conduit::Sources.names.flat_map do |source|
        database = Conduit::Sources::DATABASES.fetch(source)
        scripts(source).drop(1).map do |script|
          [database, File.basename(script, ".sql")]
        end
      end
    end

    # Missing databases and tables count as empty: they are what
    # a fresh test instance looks like before its first seeding.
    def row_count(client, database, table)
      return 0 unless scalar(client, "SELECT DB_ID('#{database}')")

      qualified = "[#{database}].dbo.[#{table}]"
      return 0 unless scalar(client, "SELECT OBJECT_ID('#{qualified}')")

      scalar(client, "SELECT COUNT(*) FROM #{qualified}")
    end

    def scalar(client, sql)
      client.execute(sql).first.values.first
    end

    # A source's scripts live in the directory named after its
    # database: database.sql first, then the table files sorted.
    def scripts(source)
      directory =
        File.join(SEEDS_ROOT, Conduit::Sources::DATABASES.fetch(source))
      bootstrap = File.join(directory, "database.sql")

      [bootstrap, *(Dir[File.join(directory, "*.sql")].sort - [bootstrap])]
    end

    # The seed scripts use sqlcmd's GO separators, which are not
    # T-SQL: each batch must be sent to the server on its own.
    def batches(script)
      sql = File.read(script)
      sql.split(/^\s*GO\s*$/i).map(&:strip).reject(&:empty?)
    end

    def real_instance_message(location, oversized)
      tables = oversized.map { |db, table| "  #{db}.dbo.#{table}" }

      <<~MESSAGE
        Refusing to seed the MSSQL instance at
        #{location[:host]}:#{location[:port]}. These tables hold
        more than #{MAX_TEST_TABLE_ROWS} rows — no seed produces
        that many, so this looks like a real instance, not a
        disposable test one:

        #{tables.join("\n")}

        Nothing was executed against it. Point the specs at a
        test instance with CONDUIT_MSSQL_HOST and CONDUIT_MSSQL_PORT.
      MESSAGE
    end

    def unavailable_message(location, error)
      <<~MESSAGE
        Conduit's integration specs need an external MSSQL instance,
        but seeding the instance at
        #{location[:host]}:#{location[:port]} failed:

          #{error.message}

        Start the local Docker instance with `mise run mssql:up`, or
        point the specs at another one with CONDUIT_MSSQL_HOST and
        CONDUIT_MSSQL_PORT.

        To skip the integration specs, set CONDUIT_SKIP_MSSQL=1.
      MESSAGE
    end
  end
end

# Seed only when this run includes :mssql examples: not when a
# unit-only file is targeted, and not when CONDUIT_SKIP_MSSQL
# excludes the integration tier.
RSpec.configure do |config|
  config.when_first_matching_example_defined(:mssql) do
    config.before(:suite) do
      ConduitSpec::Seeder.seed! unless ENV["CONDUIT_SKIP_MSSQL"]
    end
  end
end
