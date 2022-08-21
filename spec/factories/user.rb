# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
FactoryBot.define do
  sequence :user_login do |n|
    "customer#{n}"
  end

  sequence :reseller_login do |n|
    "reseller#{n}"
  end

  factory :user, class: User do
    name { 'Customer' }
    login { generate(:user_login) }
    password { 'customer' }
    enabled { true }

    transient do
      group_name { 'user' }
      package_count { 1 }
    end

    group_id do
      if Group.first(name: group_name).nil?
        create(:group, name: group_name).id
      else
        Group.first(name: group_name).id
      end
    end

    after(:create) do |user, evaluator|
      user.packages = create_list(:package, evaluator.package_count)
      user.save
    end

    factory :invalid_user do
      name { nil }
      login { nil }
    end

    factory :admin, parent: :user do
      name { 'Admin' }
      login { 'admin' }
      password { 'secret' }

      transient do
        group_name { 'admin' }
      end
    end

    factory :reseller, parent: :user do
      name { 'Reseller' }
      login { generate(:reseller_login) }
      password { 'reseller' }

      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count)
        user.save
      end

      transient do
        group_name { 'reseller' }
      end
    end

    factory :reseller_with_exhausted_customer_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_customers: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_apikey_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_apikeys: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_custom_packages_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_custom_packages: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_domain_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_domains: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_mailaccount_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_accounts: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_mailforwarding_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_forwardings: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_mailalias_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_aliases: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_mailsource_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_sources: 0)
        user.save
      end
    end

    factory :reseller_with_exhausted_mailstorage_quota, parent: :reseller do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_storage: 0)
        user.save
      end
    end

    factory :reseller_with_customers, parent: :reseller do
      transient do
        customer_count { 3 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_customers: 5)
        user.save
      end

      after(:create) do |reseller, evaluator|
        reseller.customers = create_list(:user,
                                         evaluator.customer_count,
                                         reseller_id: reseller.id)
        reseller.save
      end
    end

    factory :reseller_with_customers_and_apikeys, parent: :reseller do
      transient do
        customer_count { 3 }
        apikey_count { 1 }
      end

      after(:create) do |reseller, evaluator|
        reseller.packages = create_list(:reseller_package,
                                        evaluator.package_count,
                                        quota_customers: 5,
                                        quota_apikeys: 5)
        reseller.save

        create_list(:user, evaluator.customer_count, reseller_id: reseller.id)
        create(:apikey, user_id: reseller.id)

        reseller.customers.each do |customer|
          create(:apikey, user_id: customer.id)
        end
      end
    end

    factory :reseller_with_customers_and_domains, parent: :reseller do
      transient do
        customer_count { 3 }
        domain_count { 3 }
      end

      after(:create) do |reseller, evaluator|
        reseller.packages = create_list(:reseller_package,
                                        evaluator.package_count,
                                        quota_customers: 5,
                                        quota_domains: 15)
        reseller.save

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

    factory :reseller_with_customers_and_mailaccounts,
            parent: :reseller_with_customers_and_domains do
      transient do
        mailaccount_count { 3 }
      end

      after(:create) do |reseller, evaluator|
        reseller.packages = create_list(
          :reseller_package,
          evaluator.package_count,
          quota_customers: 5,
          quota_domains: 15,
          quota_mail_accounts: 45,
          quota_mail_storage: 471_859_200 # 45*10 MiB
        )
        reseller.save

        reseller.domains.each do |domain|
          create_list(:mailaccount,
                      evaluator.mailaccount_count,
                      domain_id: domain.id)
        end
        reseller.customers.domains.each do |domain|
          create_list(:mailaccount,
                      evaluator.mailaccount_count,
                      domain_id: domain.id)
        end
      end
    end
    factory :reseller_with_customers_and_mailforwardings,
            parent: :reseller_with_customers_and_domains do
      transient do
        mailforwarding_count { 3 }
      end

      after(:create) do |reseller, evaluator|
        reseller.packages = create_list(
          :reseller_package,
          evaluator.package_count,
          quota_customers: 5,
          quota_domains: 15,
          quota_mail_forwardings: 90
        )
        reseller.save

        reseller.domains.each do |domain|
          create_list(:mailforwarding,
                      evaluator.mailforwarding_count,
                      domain_id: domain.id)
        end
        reseller.customers.domains.each do |domain|
          create_list(:mailforwarding,
                      evaluator.mailforwarding_count,
                      domain_id: domain.id)
        end
      end
    end

    factory :reseller_with_customers_and_mailaliases,
            parent: :reseller_with_customers_and_mailaccounts do
      transient do
        mailalias_count { 3 }
      end

      after(:create) do |reseller, evaluator|
        reseller.packages = create_list(
          :reseller_package,
          evaluator.package_count,
          quota_customers: 5,
          quota_domains: 15,
          quota_mail_accounts: 45,
          quota_mail_aliases: 120,
          quota_mail_storage: 471_859_200 # 45*10 MiB
        )
        reseller.save

        reseller.domains.mail_accounts.each do |mailaccount|
          aliases = create_list(:mailalias,
                                evaluator.mailalias_count,
                                domain_id: mailaccount.domain_id)
          mailaccount.mail_aliases = aliases
        end
        reseller.customers.domains.mail_accounts.each do |mailaccount|
          aliases = create_list(:mailalias,
                                evaluator.mailalias_count,
                                domain_id: mailaccount.domain_id)
          mailaccount.mail_aliases = aliases
        end
      end
    end

    factory :reseller_with_customers_and_mailsources,
            parent: :reseller_with_customers_and_mailaccounts do
      transient do
        mailsource_count { 3 }
      end

      after(:create) do |reseller, evaluator|
        reseller.packages = create_list(
          :reseller_package,
          evaluator.package_count,
          quota_customers: 5,
          quota_domains: 15,
          quota_mail_accounts: 45,
          quota_mail_sources: 120,
          quota_mail_storage: 471_859_200 # 45*10 MiB
        )
        reseller.save

        reseller.domains.mail_accounts.each do |mailaccount|
          sources = create_list(:mailsource,
                                evaluator.mailsource_count,
                                domain_id: mailaccount.domain_id)
          mailaccount.mail_sources = sources
        end
        reseller.customers.domains.mail_accounts.each do |mailaccount|
          sources = create_list(:mailsource,
                                evaluator.mailsource_count,
                                domain_id: mailaccount.domain_id)
          mailaccount.mail_sources = sources
        end
      end
    end

    factory :reseller_with_customers_and_dkims,
            parent: :reseller_with_customers_and_mailaccounts do
      after(:create) do |reseller, _evaluator|
        reseller.domains.each do |domain|
          create(:dkim, domain_id: domain.id)
        end
        reseller.customers.domains.each do |domain|
          create(:dkim, domain_id: domain.id)
        end
      end
    end

    factory :reseller_with_customers_and_dkimsignings,
            parent: :reseller_with_customers_and_dkims do
      after(:create) do |reseller, _evaluator|
        reseller.domains.each do |domain|
          domain.dkims.each do |dkim|
            create(:dkimsigning, author: "@#{domain.name}", dkim_id: dkim.id)
          end
        end
        reseller.customers.domains.each do |domain|
          domain.dkims.each do |dkim|
            create(:dkimsigning, author: "@#{domain.name}", dkim_id: dkim.id)
          end
        end
      end
    end

    factory :reseller_with_customers_and_apikeys_and_exhausted_apikey_quota,
            parent: :reseller_with_customers_and_apikeys do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_apikeys: 4)
        user.save
      end
    end

    factory :reseller_with_customers_and_domains_and_exhausted_domain_quota,
            parent: :reseller_with_customers_and_domains do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_domains: 12)
        user.save
      end
    end

    factory :reseller_with_customers_and_mailaccounts_and_exhausted_quota,
            parent: :reseller_with_customers_and_mailaccounts do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_domains: 12,
                                    quota_mail_accounts: 36)
        user.save
      end
    end

    factory :reseller_with_customers_and_mailforwardings_and_exhausted_quota,
            parent: :reseller_with_customers_and_mailforwardings do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_forwardings: 72)
        user.save
      end
    end

    factory :reseller_with_customers_and_mailaliases_and_exhausted_quota,
            parent: :reseller_with_customers_and_mailaliases do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_aliases: 108)
        user.save
      end
    end

    factory :reseller_with_customers_and_mailsources_and_exhausted_quota,
            parent: :reseller_with_customers_and_mailsources do
      after(:create) do |user, evaluator|
        user.packages = create_list(:reseller_package,
                                    evaluator.package_count,
                                    quota_mail_sources: 108)
        user.save
      end
    end

    factory :user_with_exhausted_apikey_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_apikeys: 0)
        user.save
      end
    end

    factory :user_with_exhausted_domain_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_domains: 0)
        user.save
      end
    end

    factory :user_with_exhausted_mailaccount_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_accounts: 0)
        user.save
      end
    end

    factory :user_with_exhausted_mailforwarding_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_forwardings: 0)
        user.save
      end
    end

    factory :user_with_exhausted_mailalias_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_aliases: 0)
        user.save
      end
    end

    factory :user_with_exhausted_mailsource_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_sources: 0)
        user.save
      end
    end

    factory :user_with_exhausted_mailstoragee_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_storage: 0)
        user.save
      end
    end

    factory :user_with_exhausted_dnszone_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_dns_zones: 0)
        user.save
      end
    end

    factory :user_with_exhausted_dnsrecords_quota do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_dns_records: 0)
        user.save
      end
    end

    factory :user_with_apikeys, parent: :user do
      transient do
        apikey_count { 1 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_apikeys: 3)
        user.save
      end

      after(:create) do |user, _evaluator|
        create(:apikey, user_id: user.id)
      end
    end

    factory :user_with_domains do
      transient do
        domain_count { 3 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_domains: 5)
        user.save
      end

      after(:create) do |user, evaluator|
        create_list(:domain,
                    evaluator.domain_count,
                    user_id: user.id)
      end
    end

    factory :user_with_apikeys_and_exhausted_apikey_quota,
            parent: :user_with_apikeys do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_apikeys: 1)
        user.save
      end
    end

    factory :user_with_domains_and_exhausted_domain_quota,
            parent: :user_with_domains do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_domains: 3)
        user.save
      end
    end

    factory :user_with_mailaccounts_and_exhausted_mailaccount_quota,
            parent: :user_with_mailaccounts do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_domains: 3,
                                    quota_mail_accounts: 9)
        user.save
      end
    end

    factory :user_with_mailforwardings_and_exhausted_mailforwarding_quota,
            parent: :user_with_mailforwardings do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_forwardings: 18)
        user.save
      end
    end

    factory :user_with_mailaliases_and_exhausted_mailalias_quota,
            parent: :user_with_mailaliases do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_aliases: 27)
        user.save
      end
    end

    factory :user_with_mailsources_and_exhausted_mailsource_quota,
            parent: :user_with_mailsources do
      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_sources: 27)
        user.save
      end
    end

    factory :user_with_mailaccounts, parent: :user_with_domains do
      transient do
        mailaccount_count { 3 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_accounts: 15)
        user.save
      end

      after(:create) do |user, evaluator|
        user.domains.each do |domain|
          create_list(:mailaccount,
                      evaluator.mailaccount_count,
                      domain_id: domain.id)
        end
      end
    end

    factory :user_with_mailforwardings, parent: :user_with_domains do
      transient do
        mailforwarding_count { 3 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_forwardings: 30)
        user.save
      end

      after(:create) do |user, evaluator|
        user.domains.each do |domain|
          create_list(:mailforwarding,
                      evaluator.mailforwarding_count,
                      domain_id: domain.id)
        end
      end
    end

    factory :user_with_mailaliases, parent: :user_with_mailaccounts do
      transient do
        mailalias_count { 3 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_aliases: 30)
        user.save
      end

      after(:create) do |user, evaluator|
        user.domains.mail_accounts.each do |mailaccount|
          aliases = create_list(:mailalias,
                                evaluator.mailalias_count,
                                domain_id: mailaccount.domain_id)
          mailaccount.mail_aliases = aliases
        end
      end
    end

    factory :user_with_mailsources, parent: :user_with_mailaccounts do
      transient do
        mailsource_count { 3 }
      end

      after(:create) do |user, evaluator|
        user.packages = create_list(:package,
                                    evaluator.package_count,
                                    quota_mail_sources: 30)
        user.save
      end

      after(:create) do |user, evaluator|
        user.domains.mail_accounts.each do |mailaccount|
          sources = create_list(:mailsource,
                                evaluator.mailsource_count,
                                domain_id: mailaccount.domain_id)
          mailaccount.mail_sources = sources
        end
      end
    end

    factory :user_with_dkims, parent: :user_with_mailaccounts do
      after(:create) do |user, _evaluator|
        user.domains.each do |domain|
          create(:dkim, domain_id: domain.id)
        end
      end
    end

    factory :user_with_dkimsignings, parent: :user_with_dkims do
      after(:create) do |user, _evaluator|
        user.domains.each do |domain|
          domain.dkims.each do |dkim|
            create(:dkimsigning, author: "@#{domain.name}", dkim_id: dkim.id)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
