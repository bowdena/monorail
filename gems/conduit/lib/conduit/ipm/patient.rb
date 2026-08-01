module Conduit
  module IPM
    class Patient < ROM::Struct
      attribute :urn, ROM::Types::Strict::String
      attribute :first_name, ROM::Types::Strict::String.optional
      attribute :last_name, ROM::Types::Strict::String
      attribute :date_of_birth, ROM::Types::Strict::Date.optional
      attribute :gender, ROM::Types::Strict::String.optional
      attribute :atsi_status, ROM::Types::Strict::String.optional
      attribute :merged_from, ROM::Types::Strict::String.optional

      def merged?
        !merged_from.nil?
      end
    end
  end
end
