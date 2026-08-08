module Conduit
  module IPM
    module Relations
      class MergedPatients < ROM::Relation[:sql]
        gateway :ipm

        schema(:MERGED_PATIENTS, as: :ipm_merged_patients) do
          attribute :patnt_refno, Types::Decimal,
            read: Types.Constructor(Integer, &:to_i)
          attribute :prev_patnt_refno, Types::Decimal,
            read: Types.Constructor(Integer, &:to_i)
          attribute :archv_flag, Types::String
        end

        def active
          where(archv_flag: "N")
        end

        # The record a superseded one was merged into, or nil when
        # it has not been merged. iPM writes one row per record
        # moved, so a single merge repeats once per record it
        # touched — thousands of times for a long-lived patient.
        # Distinct collapses them back to the one merge they
        # describe.
        def survivor_for(superseded_refno)
          active
            .where(prev_patnt_refno: superseded_refno)
            .select(:patnt_refno)
            .distinct
            .pluck(:patnt_refno)
            .first&.to_i
        end
      end
    end
  end
end
