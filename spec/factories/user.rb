# frozen_string_literal: true
FactoryGirl.define do
  factory :admin, class: User do
    name 'Admin'
    login 'admin'
    password 'secret'
    association :group, factory: :admin_group, strategy: :create
    enabled true
  end

  factory :reseller, class: User do
    name 'Reseller'
    login 'reseller'
    password 'reseller'
    association :group, factory: :reseller_group, strategy: :create
    enabled true
  end

  factory :customer, class: User do
    name 'Customer'
    login 'customer'
    password 'customer'
    association :group, factory: :customer_group, strategy: :create
    enabled true
  end
end
