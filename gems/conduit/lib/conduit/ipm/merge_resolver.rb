module Conduit
  module IPM
    # Resolves iPM's patient merge chains. A retired record points at
    # the record it was merged into (MERGED_PATIENTS), and merges can
    # chain, so a searched row is followed to the current live record.
    #
    # Chains are followed for a whole row set at once, one query per
    # generation of the merge graph, so resolution costs what the
    # chains are deep rather than what the search matched.
    class MergeResolver
      def initialize(patients, merged_patients)
        @patients = patients
        @merged_patients = merged_patients
      end

      # Returns [current row, searched urn] — the urn is nil when no
      # merge was crossed, and both are nil when nothing resolved.
      def resolve(searched)
        return [nil, nil] unless searched

        resolve_all([searched]).first || [nil, nil]
      end

      # Rows resolving to the same current patient collapse to one
      # [tuple, merged_from] pair — a direct hit always wins over merge
      # metadata — ordered by name for deterministic output.
      def resolve_all(rows)
        chains = merge_chains(rows)
        current = current_rows(chains)

        rows.filter_map { |row| resolution(row, chains, current) }
          .group_by { |resolved, _merged_from| resolved[:patnt_refno] }
          .values
          .map { |group| collapse(group) }
          .sort_by do |tuple, _merged_from|
            [tuple[:last_name], tuple[:first_name].to_s]
          end
      end

      private

      # Every row's chain of refnos, from the searched record to the
      # current one, keyed by the searched record. A chain ends where
      # nothing was merged, or where it doubles back on a refno it has
      # already visited.
      def merge_chains(rows)
        chains = rows.to_h { |row| [row[:patnt_refno], [row[:patnt_refno]]] }
        unfinished = chains.values

        until unfinished.empty?
          targets =
            @merged_patients.latest_targets(unfinished.map(&:last).uniq)

          unfinished = unfinished.select do |chain|
            extended?(chain, targets[chain.last])
          end
        end

        chains
      end

      def extended?(chain, target)
        return false if target.nil? || chain.include?(target)

        chain << target
        true
      end

      # Only chains that moved need their current record loading; a
      # row that was never merged is already the record to return.
      def current_rows(chains)
        moved = chains.values.select { |chain| chain.length > 1 }
        return {} if moved.empty?

        @patients.active_by_refnos(moved.map(&:last).uniq)
      end

      def resolution(row, chains, current)
        chain = chains[row[:patnt_refno]]
        return [row, nil] if chain.length == 1

        resolved = current[chain.last]
        resolved ? [resolved, row[:urn]] : nil
      end

      def collapse(group)
        group.find { |_tuple, merged_from| merged_from.nil? } ||
          group.first
      end
    end
  end
end
