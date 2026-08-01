module Conduit
  # Builds the ROM container at configure time: one SQL gateway per
  # configured source, with that source's relations registered
  # against it.
  module Container
    RELATIONS = {
      ipm: -> {
        [IPM::Relations::Patients,
          IPM::Relations::MergedPatients,
          IPM::Relations::ReferenceValues]
      }
    }.freeze

    unless (RELATIONS.keys - Sources.names).empty?
      raise "Container::RELATIONS names unknown sources: " \
            "#{(RELATIONS.keys - Sources.names).join(", ")} " \
            "(known: #{Sources.names.join(", ")})"
    end

    class << self
      def build(configuration)
        names = Sources.names.select do |name|
          configuration.configured?(name)
        end

        ROM.container(gateways(names, configuration)) do |config|
          names.flat_map { |name| RELATIONS.fetch(name, -> { [] }).call }
            .each { |relation| config.register_relation(relation) }
        end
      end

      private

      def gateways(names, configuration)
        names.to_h do |name|
          settings = Sources.settings(name)
          credentials = configuration.credentials_for(name)

          [name, [:sql, Sequel.connect(
            adapter: "tinytds",
            host: settings[:host],
            port: settings[:port],
            database: settings[:database],
            user: credentials.username,
            password: credentials.password,
            # allow parameter injection for testing
            login_timeout:
              Integer(ENV.fetch("CONDUIT_LOGIN_TIMEOUT", 5)),
            timeout: 30,
            max_connections: 5,
            test: false
          )]]
        end
      end
    end
  end
end
