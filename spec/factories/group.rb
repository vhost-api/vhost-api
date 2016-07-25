# frozen_string_literal: true
FactoryGirl.define do
  # factory :admin_group, class: Group do
  # name 'admin'
  # enabled true
  # end

  # factory :reseller_group, class: Group do
  # name 'reseller'
  # enabled true
  # end

  # factory :user_group, class: Group do
  # name 'user'
  # enabled true
  # end

  factory :group, class: Group do
    name 'user'
    enabled true

    factory :invalid_group do
      name nil
    end
  end
end
