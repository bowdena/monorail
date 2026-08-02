module Conduit
  # Inherits ROM::Repository::Root, not ROM::Repository.
  class Repository < ROM::Repository::Root
    ERROR_NUMBERS = {
      18456 => Error::AuthenticationFailed, # login failed
      911 => Error::PermissionDenied, # database doesn't exist
      4060 => Error::PermissionDenied, # can't open database
      229 => Error::PermissionDenied, # permission denied
      230 => Error::PermissionDenied, # permission denied
      20003 => Error::Timeout, # TDS timed out
      20009 => Error::ConnectionFailed, # TDS unable to connect
      20047 => Error::ConnectionFailed # TDS connection dead
    }.freeze

    # Message fallbacks for failures that surface without a number.
    CONNECTION_FAILURE =
      /Unable to connect|Adaptive Server|Server name not found/i
    PERMISSION_DENIED = /permission was denied|Cannot open database/i
    AUTHENTICATION_FAILED = /Login failed/i

    private

    def relation(name)
      container.relations[name]
    end

    def source
      raise NotImplementedError, "#{self.class} must declare its source"
    end

    def resource_name
      raise NotImplementedError,
        "#{self.class} must declare its resource_name"
    end

    def record_identifier(record)
      raise NotImplementedError,
        "#{self.class} must identify its records"
    end

    def one(name, params, &query)
      audited(name, params) { [guarded(&query)].compact }.first
    end

    def many(name, params, &query)
      audited(name, params) { guarded(&query) }
    end

    # Wraps a query in one query.conduit event — metadata and
    # record identifiers only, never row data. A classified
    # failure is recorded on the event and re-raised, as is a page
    # the caller asked for and the result set does not have: the
    # query ran, so the trail should say so.
    def audited(name, params)
      payload = {
        application: Conduit.configuration&.application,
        source: source, resource: resource_name, name: name,
        params: params
      }

      ActiveSupport::Notifications.instrument("query.conduit", payload) do
        records = yield
        payload[:row_count] = records.length
        payload[:record_ids] =
          records.map { |record| record_identifier(record) }
        records
      rescue Error, ArgumentError => error
        payload[:error] = error.class.name
        raise
      end
    end

    # Translates driver failures at the gem boundary. Anything
    # that is not a database failure — a gem bug, say — is left
    # alone: masquerading defects as infrastructure errors would
    # misdirect the consumer's error handling.
    def guarded
      yield
    rescue Sequel::DatabaseConnectionError => error
      raise classified(error, Error::ConnectionFailed)
    rescue Sequel::DatabaseError, TinyTds::Error => error
      raise classified(error, Error::QueryError)
    end

    def classified(error, default)
      error_class(error, default)
        .new(error.message, source: source, cause: error)
    end

    # Number first; the message regexes only catch failures that
    # surface without one.
    def error_class(error, default)
      ERROR_NUMBERS.fetch(db_error_number(error)) do
        message_class(error.message) || default
      end
    end

    def db_error_number(error)
      driver =
        error.is_a?(TinyTds::Error) ? error : error.wrapped_exception

      driver.db_error_number if driver.respond_to?(:db_error_number)
    end

    def message_class(message)
      case message
      when CONNECTION_FAILURE then Error::ConnectionFailed
      when PERMISSION_DENIED then Error::PermissionDenied
      when AUTHENTICATION_FAILED then Error::AuthenticationFailed
      end
    end
  end
end
