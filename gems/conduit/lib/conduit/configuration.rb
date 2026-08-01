module Conduit
  class Configuration
    Credentials = Data.define(:username, :password)

    attr_accessor :application

    def initialize
      @credentials = {}
    end

    def source(name, username:, password:)
      unless Sources.names.include?(name)
        raise ArgumentError, "Unknown conduit source: #{name}. " \
                             "Known sources: #{Sources.names.join(", ")}"
      end
      if username.to_s.empty?
        raise ArgumentError, "username is required for source #{name}"
      end
      if password.to_s.empty?
        raise ArgumentError, "password is required for source #{name}"
      end

      @credentials[name] = Credentials.new(username:, password:)
    end

    def configured?(name)
      @credentials.key?(name)
    end

    def credentials_for(name)
      @credentials[name]
    end
  end
end
