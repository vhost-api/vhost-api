# frozen_string_literal: true

FactoryBot.define do
  sequence :random_apikey do
    SecureRandom.hex(32)
  end

  factory :apikey, class: Apikey do
    apikey { generate(:random_apikey) }
    enabled true

    transient do
      user_login 'user'
    end

    user_id do
      if User.first(login: user_login).nil?
        create(:user, login: user_login).id
      else
        User.first(login: user_login).id
      end
    end

    factory :invalid_apikey do
      apikey '1234'
    end
  end
end
