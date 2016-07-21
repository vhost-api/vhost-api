# frozen_string_literal: true
FactoryGirl.define do
  factory :dkim, class: Dkim do
    selector 'mail'
    private_key '-----BEGIN RSA PRIVATE KEY-----\n
      some random private characters.......\n
      -----END RSA PRIVATE KEY-----'
    public_key '-----BEGIN PUBLIC KEY-----\n
      some random public characters.......\n
      -----END PUBLIC KEY-----'
    association :domain, factory: :domain, strategy: :create
    enabled true
  end
end
