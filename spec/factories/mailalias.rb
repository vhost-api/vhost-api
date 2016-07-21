# frozen_string_literal: true
FactoryGirl.define do
  sequence :alias_email do |n|
    "alias#{n}@example.com"
  end

  factory :mailalias, class: MailAlias do
    address { generate(:alias_email) }
    enabled true

    transient do
      domain_name 'example.com'
    end

    domain do
      Domain.first(name: domain_name) || create(:domain, name: domain_name)
    end
  end
end
