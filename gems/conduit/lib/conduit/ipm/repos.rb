module Conduit
  module IPM
    class Repos
      def initialize(container)
        @container = container
      end

      def patients
        @patients ||= Repositories::Patients.new(@container)
      end
    end
  end
end
