# frozen_string_literal: true
FactoryGirl.define do
  sequence :account_email do |n|
    "test#{n}@example.com"
  end

  factory :mailaccount, class: MailAccount do
    email { generate(:account_email) }
    realname 'Test User'
    password 'foobar1234'
    receiving_enabled true
    enabled true

    transient do
      domain_name 'example.com'
    end

    domain do
      Domain.first(name: domain_name) || create(:domain, name: domain_name)
    end

    factory :mailaccount_with_aliases_and_sources do
      transient do
        alias_count 3
        source_count 3
      end

      after(:create) do |mailaccount, evaluator|
        create_list(:mailalias,
                    evaluator.alias_count,
                    mail_accounts: [mailaccount])
        create_list(:mailsource,
                    evaluator.source_count,
                    mail_accounts: [mailaccount])
      end
    end
  end
end
