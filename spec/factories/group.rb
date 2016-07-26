# frozen_string_literal: true
FactoryGirl.define do
  factory :group, class: Group do
    name 'user'
    enabled true

    factory :invalid_group do
      name nil
    end
  end
end
