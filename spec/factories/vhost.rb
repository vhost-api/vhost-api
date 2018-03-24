# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
FactoryGirl.define do
  sequence :random_fqdn do |n|
    "example#{n}.org"
  end

  factory :vhost, class: Vhost do
    fqdn { generate(:random_fqdn) }
    quota 104_857_600
    enabled true

    transient do
      user_login 'user'
      ipv4addr IPAddr.new('127.0.0.1')
      ipv6addr IPAddr.new('fe80::1')
    end

    user_id do
      if User.first(login: user_login).nil?
        create(:user, login: user_login).id
      else
        User.first(login: user_login).id
      end
    end

    ipv4_address_id do
      if Ipv4Address.first(address: ipv4addr).nil?
        create(:ipv4address, address: ipv4addr).id
      else
        Ipv4Address.first(address: ipv4addr).id
      end
    end

    ipv6_address_id do
      if Ipv6Address.first(address: ipv6addr).nil?
        create(:ipv6address, address: ipv6addr).id
      else
        Ipv6Address.first(address: ipv6addr).id
      end
    end

    factory :invalid_vhost do
      fqdn nil
    end
  end
end
# rubocop:enable Metrics/BlockLength
