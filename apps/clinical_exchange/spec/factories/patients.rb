FactoryBot.define do
  factory :patient do
    sequence(:urn) { |n| n.to_s.rjust(7, "0") }
    first_name { "Tori" }
    last_name { "Judd" }
    date_of_birth { Date.new(1957, 9, 29) }
    gender { "Female" }
  end
end
