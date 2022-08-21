# frozen_string_literal: true

FactoryBot.define do
  sequence :domain_name do |n|
    "example#{n}.org"
  end

  factory :domain, class: Domain do
    name { generate(:domain_name) }
    mail_enabled { true }
    dns_enabled { true }
    enabled { true }

    transient do
      user_login { 'user' }
    end

    user_id do
      if User.first(login: user_login).nil?
        create(:user, login: user_login).id
      else
        User.first(login: user_login).id
      end
    end

    factory :invalid_domain do
      name { nil }
    end
  end
end
