module Conduit
  module IPM
    module Relations
      class ReferenceValues < ROM::Relation[:sql]
        gateway :ipm

        schema(:REFERENCE_VALUES, as: :ipm_reference_values) do
          attribute :rfval_refno, Types::Decimal,
            read: Types.Constructor(Integer, &:to_i)
          attribute :rfvdm_code, Types::String
          attribute :description, Types::String
        end
      end
    end
  end
end
