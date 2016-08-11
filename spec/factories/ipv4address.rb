# frozen_string_literal: true
FactoryGirl.define do
  factory :ipv4address, class: Ipv4Address do
    address IPAddr.new('127.0.0.1')
    enabled true

    factory :invalid_ipv4address do
      address nil
    end
  end
end
