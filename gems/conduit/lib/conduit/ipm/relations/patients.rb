module Conduit
  module IPM
    module Relations
      class Patients < ROM::Relation[:sql]
        gateway :ipm

        schema(:PATIENTS, as: :ipm_patients) do
          attribute :patnt_refno, Types::Decimal,
            read: Types.Constructor(Integer, &:to_i)
          attribute :pasid, Types::String, alias: :urn
          attribute :forename, Types::String, alias: :first_name
          attribute :surname, Types::String, alias: :last_name
          attribute :upper_forename, Types::String
          attribute :upper_surname, Types::String
          attribute :dttm_of_birth, Types::Time,
            read: Types.Constructor(Date) { |value| value&.to_date },
            alias: :date_of_birth
          attribute :gendr_refno, Types::Decimal,
            read: Types.Constructor(Integer, &:to_i)
          attribute :ethgr_refno, Types::Decimal,
            read: Types.Constructor(Integer, &:to_i)
          attribute :archv_flag, Types::String
        end

        def active
          where(archv_flag: "N")
        end

        # The active patient row for an internal reference, or nil.
        def active_by_refno(patnt_refno)
          active.where(patnt_refno: patnt_refno).one
        end

        # The active patient row for an external URN, or nil.
        def by_pasid(urn)
          active.where(pasid: urn).one
        end

        # Exact, case-insensitive name matching via the upper_
        # columns iPM maintains; date of birth matches the stored
        # midnight datetime. Blank criteria are ignored.
        def exact_match(criteria)
          scope = active
          if (first_name = criteria[:first_name])
            scope = scope.where(upper_forename: first_name.upcase)
          end
          if (last_name = criteria[:last_name])
            scope = scope.where(upper_surname: last_name.upcase)
          end
          if (date_of_birth = criteria[:date_of_birth])
            scope = scope.where(dttm_of_birth: date_of_birth)
          end
          scope
        end

        # Like exact_match, but names match on any fragment. Date of
        # birth stays exact — a fuzzy date has no meaning.
        def fuzzy_match(criteria)
          scope = active
          if (first_name = criteria[:first_name])
            term = like_term(first_name)
            scope = scope.where { upper_forename.like(term) }
          end
          if (last_name = criteria[:last_name])
            term = like_term(last_name)
            scope = scope.where { upper_surname.like(term) }
          end
          if (date_of_birth = criteria[:date_of_birth])
            scope = scope.where(dttm_of_birth: date_of_birth)
          end
          scope
        end

        private

        def like_term(name)
          escaped = dataset.escape_like(name.upcase)
          "%#{escaped}%"
        end
      end
    end
  end
end
