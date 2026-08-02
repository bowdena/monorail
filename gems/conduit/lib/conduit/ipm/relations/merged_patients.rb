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

        # The record each retired record was merged into, keyed by the
        # retired record and covering only those that were merged.
        # Oldest first, so the newest merge for a record is the one
        # left standing in the hash.
        def latest_targets(prev_patnt_refnos)
          return {} if prev_patnt_refnos.empty?

          active
            .where(prev_patnt_refno: prev_patnt_refnos)
            .order { create_dttm.asc }
            .to_a
            .to_h { |row| [row[:prev_patnt_refno], row[:patnt_refno]] }
        end
      end
    end
  end
end
