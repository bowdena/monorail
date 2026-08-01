module Conduit
  module IPM
    # Maps iPM patient tuples to Patient structs, enriching coded
    # reference values (gender, ATSI status) through the reference
    # lookup and carrying the merge origin through.
    class PatientMapper
      def initialize(reference_lookup)
        @reference_lookup = reference_lookup
      end

      def call(tuple, merged_from:)
        Patient.new(
          urn: tuple[:urn],
          first_name: tuple[:first_name],
          last_name: tuple[:last_name],
          date_of_birth: tuple[:date_of_birth],
          gender: description(tuple[:gendr_refno], "GENDR"),
          atsi_status: description(tuple[:ethgr_refno], "ETHGR"),
          merged_from: merged_from
        )
      end

      def call_all(resolutions)
        resolutions.map do |tuple, merged_from|
          call(tuple, merged_from: merged_from)
        end
      end

      private

      def description(refno, domain)
        @reference_lookup.description_for(refno, domain)
      end
    end
  end
end
