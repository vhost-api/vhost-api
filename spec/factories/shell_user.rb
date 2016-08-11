# frozen_string_literal: true
FactoryGirl.define do
  sequence :shell_username do |n|
    "customer#{n}"
  end

  factory :shelluser, class: ShellUser do
    username { generate(:shell_username) }
    password 'shelluser'
    uid 5001
    gid 5001
    enabled true

    transient do
      shell '/bin/bash'
      vhost 'example.com'
    end

    shell_id do
      if Shell.first(shell: shell).nil?
        create(:shell, shell: shell).id
      else
        Shell.first(shell: shell).id
      end
    end

    vhost_id do
      if Vhost.first(fqdn: vhost).nil?
        create(:vhost, fqdn: vhost).id
      else
        Vhost.first(fqdn: vhost).id
      end
    end

    factory :invalid_shelluser do
      username nil
    end
  end
end
