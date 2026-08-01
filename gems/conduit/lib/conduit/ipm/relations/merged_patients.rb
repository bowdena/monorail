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
          attribute :create_dttm, Types::Time
          attribute :archv_flag, Types::String
        end

        def active
          where(archv_flag: "N")
        end

        # The most recent record a retired record was merged into,
        # or nil when it has not been merged.
        def latest_target(prev_patnt_refno)
          active
            .where(prev_patnt_refno: prev_patnt_refno)
            .order { create_dttm.desc }
            .limit(1)
            .pluck(:patnt_refno)
            .first&.to_i
        end
      end
    end
  end
end
