# frozen_string_literal: true

# spec/factories/has_states.rb
FactoryBot.define do
  factory :state, class: 'HasStates::State' do
    association :stateable, factory: :user
    state_type { 'kyc' }
    status { 'pending' }
    metadata { {} }
  end

  factory :user do
    sequence(:name) { |n| "User #{n}" }
  end

  factory :company do
    sequence(:name) { |n| "Company #{n}" }
  end
end
