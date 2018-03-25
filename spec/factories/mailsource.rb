# frozen_string_literal: true

FactoryBot.define do
  sequence :source_email do |n|
    "source#{n}@example.com"
  end

  factory :mailsource, class: MailSource do
    address { generate(:source_email) }
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

    factory :invalid_mailsource, parent: :mailsource do
      address nil
    end
  end
end
