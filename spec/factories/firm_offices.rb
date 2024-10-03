FactoryBot.define do
  factory :firm_office do
    trait :valid do
      name { 'Firm A' }
      address_line_1 { '2 Laywer Suite' }
      town { 'Lawyer Town' }
      postcode { 'CR0 1RE' }
      vat_registered { 'yes' }
    end

    trait :valid_pa do
      name { 'Firm A' }
      address_line_1 { nil }
      town { nil }
      postcode { nil }
      vat_registered { nil }
    end

    trait :full do
      valid
      address_line_2 { 'Unit B' }
      vat_registered { 'no' }
    end

    trait :randomised do
      name { Faker::Company.name }
    end
  end
end
