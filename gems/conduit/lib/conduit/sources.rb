module Conduit
  module Sources
    DATABASES = {
      ipm: "iPM_REPL"
    }.freeze

    LOCAL_LOCATION = {host: "localhost", port: 1433}.freeze
    # Development only: a suite that found an instance on localhost
    # would be answered by whatever the developer happens to be running.
    LOCAL_ENVIRONMENTS = %w[development].freeze

    class << self
      def names
        DATABASES.keys
      end

      def location(env: ENV)
        defaults = local?(env) ? LOCAL_LOCATION : {}

        {
          host: fetch(env, "CONDUIT_MSSQL_HOST", defaults[:host]),
          port: Integer(fetch(env, "CONDUIT_MSSQL_PORT", defaults[:port]))
        }
      end

      def settings(name, env: ENV)
        unless DATABASES.key?(name)
          raise ArgumentError, "Unknown conduit source: #{name}"
        end

        database_default = local?(env) ? DATABASES.fetch(name) : nil
        variable = "CONDUIT_#{name.to_s.upcase}_DATABASE"

        location(env: env).merge(
          database: fetch(env, variable, database_default)
        )
      end

      private

      def local?(env)
        environment = env["RAILS_ENV"] || env["RACK_ENV"] || "development"
        LOCAL_ENVIRONMENTS.include?(environment)
      end

      def fetch(env, key, default)
        env.fetch(key) do
          default or raise Error::NotConfigured, "#{key} is not set"
        end
      end
    end
  end
end
