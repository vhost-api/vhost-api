# frozen_string_literal: true
FactoryGirl.define do
  sequence :user_login do |n|
    "customer#{n}"
  end

  sequence :reseller_login do |n|
    "reseller#{n}"
  end

  factory :user, class: User do
    name 'Customer'
    login { generate(:user_login) }
    password 'customer'
    enabled true

    transient do
      group_name 'user'
    end

    group_id do
      if Group.first(name: group_name).nil?
        create(:group, name: group_name).id
      else
        Group.first(name: group_name).id
      end
    end

    factory :invalid_user do
      name nil
      login nil
    end

    factory :admin do
      name 'Admin'
      login 'admin'
      password 'secret'

      transient do
        group_name 'admin'
      end
    end

    factory :reseller do
      name 'Reseller'
      login { generate(:reseller_login) }
      password 'reseller'

      transient do
        group_name 'reseller'
      end
    end
  end
end
