# isolated_execution_state is an internal dependency of the
# instrumenter that active_support/notifications does not load on
# its own — without it, the first instrumented query raises
# NameError.
require "active_support/isolated_execution_state"
require "active_support/notifications"
require "rom"
require "rom-sql"

require "conduit/version"
require "conduit/errors"
require "conduit/query_event"
require "conduit/sources"
require "conduit/configuration"
require "conduit/ipm/relations/patients"
require "conduit/ipm/relations/merged_patients"
require "conduit/ipm/relations/reference_values"
require "conduit/ipm/patient"
require "conduit/ipm/reference_lookup"
require "conduit/ipm/patient_mapper"
require "conduit/repository"
require "conduit/ipm/repositories/patients"
require "conduit/ipm/repos"
require "conduit/container"

module Conduit
  class << self
    attr_reader :configuration

    # The sources conduit can reach, for consumers and error
    # messages; configuring anything else raises at boot.
    def sources
      Sources.names
    end

    # Subscribes to query.conduit events, yielding a QueryEvent per
    # query (one per source leg for composed queries). Returns the
    # subscription for ActiveSupport::Notifications.unsubscribe.
    def on_query(&block)
      ActiveSupport::Notifications.subscribe("query.conduit") do |event|
        block.call(QueryEvent.from_notification(event))
      end
    end

    # Repositories for the ipm source. Raises for an unconfigured
    # source at access, so a misconfigured app cannot reach a
    # gateway at all.
    def ipm
      unless configuration&.configured?(:ipm)
        raise Error::NotConfigured.new(
          "source ipm is not configured", source: :ipm
        )
      end

      @ipm ||= IPM::Repos.new(container)
    end

    def configure
      config = Configuration.new
      yield config
      if config.application.to_s.empty?
        raise ArgumentError, "application is required"
      end

      @configuration = config
      @container = Container.build(config)
      @ipm = nil
    end

    def reset!
      @configuration = nil
      @container = nil
      @ipm = nil
    end

    private

    # Internal — consuming apps use Conduit.ipm.
    # Public API is via Repositories
    attr_reader :container
  end
end
