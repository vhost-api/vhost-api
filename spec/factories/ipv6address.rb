# frozen_string_literal: true
FactoryGirl.define do
  factory :ipv6address, class: Ipv6Address do
    address IPAddr.new('fe80::1')
    enabled true

    factory :invalid_ipv6address do
      address nil
    end
  end
end
