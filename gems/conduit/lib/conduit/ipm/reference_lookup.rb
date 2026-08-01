module Conduit
  module IPM
    # Denormalises iPM's coded reference values to their descriptions.
    # Domains are small, static lookup tables, so each is loaded once
    # and cached for the lookup's lifetime. Reads are idempotent, so a
    # concurrent double-fill is harmless.
    class ReferenceLookup
      def initialize(reference_values)
        @reference_values = reference_values
      end

      def description_for(refno, domain)
        descriptions(domain)[refno]
      end

      private

      def descriptions(domain)
        @descriptions ||= Hash.new do |cache, code|
          cache[code] = @reference_values
            .where(rfvdm_code: code)
            .to_a
            .to_h { |value| [value[:rfval_refno], value[:description]] }
        end
        @descriptions[domain]
      end
    end
  end
end
