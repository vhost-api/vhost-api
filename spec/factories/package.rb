# frozen_string_literal: true
FactoryGirl.define do
  sequence :package_name do |n|
    "Package #{n}"
  end

  factory :package, class: Package do
    name { generate(:package_name) }
    price_unit 2_99
    quota_apikeys 3
    quota_ssh_pubkeys 5
    quota_customers 0
    quota_vhosts 1
    quota_vhost_storage 104_857_600
    quota_databases 0
    quota_database_users 0
    quota_dns_zones 1
    quota_dns_records 10
    quota_domains 1
    quota_mail_accounts 5
    quota_mail_aliases 10
    quota_mail_sources 10
    quota_mail_storage 104_857_600
    quota_sftp_users 1
    quota_shell_users 0
    enabled true

    transient do
      user_login 'user'
    end

    user_id do
      if User.first(login: user_login).nil?
        create(:user, login: user_login).id
      else
        User.first(login: user_login).id
      end
    end

    factory :invalid_package do
      name nil
      price nil
      user nil
    end

    factory :reseller_package do
      quota_apikeys 10
      quota_ssh_pubkeys 10
      quota_customers 5
      quota_vhosts 25
      quota_vhost_storage 2_621_440_000
      quota_databases 0
      quota_database_users 0
      quota_dns_zones 5
      quota_dns_records 50
      quota_domains 10
      quota_mail_accounts 25
      quota_mail_aliases 50
      quota_mail_sources 50
      quota_mail_storage 1_048_576_000
      quota_sftp_users 10
      quota_shell_users 5
    end
  end
end
