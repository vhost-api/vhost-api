# frozen_string_literal: true

FactoryBot.define do
  factory :ipv6address, class: Ipv6Address do
    address do
      IPAddr.new('fe80::1')
    end

    enabled true

    factory :invalid_ipv6address do
      address nil
    end
  end
end
