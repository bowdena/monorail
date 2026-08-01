module Conduit
  module IPM
    # Resolves iPM's patient merge chains. A retired record points at
    # the record it was merged into (MERGED_PATIENTS), and merges can
    # chain, so a searched row is followed to the current live record.
    class MergeResolver
      def initialize(patients, merged_patients)
        @patients = patients
        @merged_patients = merged_patients
      end

      # Returns [current row, searched urn] — the urn is nil when no
      # merge was crossed. Resolution state stays in locals: the
      # resolver instance is shared across calls.
      def resolve(searched)
        return [nil, nil] unless searched

        seen = [searched[:patnt_refno]]
        while (target = @merged_patients.latest_target(seen.last))
          break if seen.include?(target)
          seen << target
        end

        return [searched, nil] if seen.length == 1

        current = @patients.active_by_refno(seen.last)
        [current, current && searched[:urn]]
      end

      # Rows resolving to the same current patient collapse to one
      # [tuple, merged_from] pair — a direct hit always wins over merge
      # metadata — ordered by name for deterministic output.
      def resolve_all(rows)
        rows.map { |row| resolve(row) }
          .select { |resolved, _merged_from| resolved }
          .group_by { |resolved, _merged_from| resolved[:patnt_refno] }
          .values
          .map { |group| collapse(group) }
          .sort_by do |tuple, _merged_from|
            [tuple[:last_name], tuple[:first_name].to_s]
          end
      end

      private

      def collapse(group)
        group.find { |_tuple, merged_from| merged_from.nil? } ||
          group.first
      end
    end
  end
end
