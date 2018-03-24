# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
FactoryGirl.define do
  sequence :account_email do |n|
    "test#{n}@example.org"
  end

  factory :mailaccount, class: MailAccount do
    email { generate(:account_email) }
    realname 'Test User'
    password 'foobar1234'
    receiving_enabled true
    enabled true

    transient do
      domain_name 'example.org'
    end

    domain_id do
      if Domain.first(name: domain_name).nil?
        create(:domain, name: domain_name).id
      else
        Domain.first(name: domain_name).id
      end
    end

    factory :invalid_mailaccount do
      email nil
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
# rubocop:enable Metrics/BlockLength
