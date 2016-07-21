# frozen_string_literal: true
FactoryGirl.define do
  sequence :source_email do |n|
    "source#{n}@example.com"
  end

  factory :mailsource, class: MailSource do
    address { generate(:source_email) }
    enabled true

    transient do
      domain_name 'example.com'
    end

    domain do
      Domain.first(name: domain_name) || create(:domain, name: domain_name)
    end
  end
end
