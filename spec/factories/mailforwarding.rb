# frozen_string_literal: true

FactoryBot.define do
  sequence :forwarding_email do |n|
    "forwarding#{n}@example.com"
  end

  factory :mailforwarding, class: MailForwarding do
    address { generate(:forwarding_email) }
    destinations { "foo@bar.com\nherp@derp.com" }
    enabled { true }

    transient do
      domain_name { 'example.com' }
    end

    domain_id do
      if Domain.first(name: domain_name).nil?
        create(:domain, name: domain_name).id
      else
        Domain.first(name: domain_name).id
      end
    end

    factory :invalid_mailforwarding, parent: :mailforwarding do
      address { nil }
      destinations { nil }
    end
  end
end
