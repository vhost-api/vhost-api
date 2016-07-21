# frozen_string_literal: true
FactoryGirl.define do
  factory :domain, class: Domain do
    name 'example.com'
    mail_enabled true
    dns_enabled true
    enabled true

    transient do
      user_name 'user'
    end

    user do
      User.first(login: user_name) || create(:user, login: user_name)
    end
  end
end
