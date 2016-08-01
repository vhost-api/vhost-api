# frozen_string_literal: true
FactoryGirl.define do
  keypair = SSHKey.generate(
    type: 'RSA',
    bits: 4096,
    comment: nil,
    passphrase: nil
  )

  factory :dkim, class: Dkim do
    selector 'mail'

    private_key keypair.private_key
    public_key keypair.public_key
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

    factory :invalid_dkim, parent: :dkim do
      selector nil
    end
  end
end
