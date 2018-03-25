# frozen_string_literal: true

FactoryBot.define do
  sequence :alias_email do |n|
    "alias#{n}@example.com"
  end

  factory :mailalias, class: MailAlias do
    address { generate(:alias_email) }
    enabled true

    transient do
      domain_name 'example.com'
    end

    domain_id do
      if Domain.first(name: domain_name).nil?
        create(:domain, name: domain_name).id
      else
        Domain.first(name: domain_name).id
      end
    end

    factory :invalid_mailalias, parent: :mailalias do
      address nil
    end
  end
end
