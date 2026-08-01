module Conduit
  class Error < StandardError
    attr_reader :source

    def initialize(message = nil, source: nil, cause: nil)
      super(message)
      @source = source
      @cause = cause
    end

    def cause
      @cause || super
    end

    def configuration?
      false
    end

    def transient?
      false
    end

    class NotConfigured < Error
      def configuration? = true
    end

    class ConnectionFailed < Error
      def transient? = true
    end

    class AuthenticationFailed < Error
      def configuration? = true
    end

    class Timeout < Error
      def transient? = true
    end

    class NotFound < Error; end
    class QueryError < Error; end

    class PermissionDenied < Error
      def configuration? = true
    end
  end
end
