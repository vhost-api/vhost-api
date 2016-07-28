# frozen_string_literal: true
FactoryGirl.define do
  sequence :user_login do |n|
    "customer#{n}"
  end

  sequence :reseller_login do |n|
    "reseller#{n}"
  end

  factory :user, class: User do
    name 'Customer'
    login { generate(:user_login) }
    password 'customer'
    enabled true
    quota_customers 5
    quota_domains 1

    transient do
      group_name 'user'
    end

    group_id do
      if Group.first(name: group_name).nil?
        create(:group, name: group_name).id
      else
        Group.first(name: group_name).id
      end
    end

    factory :invalid_user do
      name nil
      login nil
    end

    factory :admin, parent: :user do
      name 'Admin'
      login 'admin'
      password 'secret'

      transient do
        group_name 'admin'
      end
    end

    factory :reseller, parent: :user do
      name 'Reseller'
      login { generate(:reseller_login) }
      password 'reseller'

      transient do
        group_name 'reseller'
      end
    end

    factory :reseller_with_exhausted_customer_quota, parent: :reseller do
      quota_customers 0
    end

    factory :reseller_with_exhausted_domain_quota, parent: :reseller do
      quota_domains 0
    end

    factory :reseller_with_customers, parent: :reseller do
      transient do
        customer_count 3
      end

      quota_customers 5

      after(:create) do |reseller, evaluator|
        create_list(:user,
                    evaluator.customer_count,
                    reseller_id: reseller.id)
      end
    end

    factory :reseller_with_customers_and_domains, parent: :reseller do
      transient do
        customer_count 3
        domain_count 3
      end

      quota_customers 5
      quota_domains 15

      after(:create) do |reseller, evaluator|
        create_list(:user,
                    evaluator.customer_count,
                    reseller_id: reseller.id)
        create_list(:domain,
                    evaluator.domain_count,
                    user_id: reseller.id)
        reseller.customers.each do |customer|
          create_list(:domain,
                      evaluator.domain_count,
                      user_id: customer.id)
        end
      end
    end

    factory :reseller_with_customers_and_domains_and_exhausted_domain_quota,
            parent: :reseller_with_customers_and_domains do
      quota_domains 12
    end

    factory :user_with_exhausted_domain_quota do
      quota_domains 0
    end

    factory :user_with_exhausted_mailaccount_quota do
      quota_mail_accounts 0
    end

    factory :user_with_exhausted_mailalias_quota do
      quota_mail_aliases 0
    end

    factory :user_with_exhausted_mailsource_quota do
      quota_mail_sources 0
    end

    factory :user_with_exhausted_mailstoragee_quota do
      quota_mail_storage 0
    end

    factory :user_with_exhausted_dnszone_quota do
      quota_dns_zones 0
    end

    factory :user_with_exhausted_dnsrecords_quota do
      quota_dns_zones 0
    end

    factory :user_with_domains do
      transient do
        domain_count 3
      end

      quota_domains 5

      after(:create) do |user, evaluator|
        create_list(:domain,
                    evaluator.domain_count,
                    user_id: user.id)
      end
    end

    factory :user_with_domains_and_exhausted_domain_quota,
            parent: :user_with_domains do
      quota_domains 3
    end
  end
end
