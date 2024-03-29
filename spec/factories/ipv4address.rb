# frozen_string_literal: true

FactoryBot.define do
  factory :ipv4address, class: Ipv4Address do
    address do
      IPAddr.new('127.0.0.1')
    end

    enabled { true }

    factory :invalid_ipv4address do
      address { nil }
    end
  end
end
