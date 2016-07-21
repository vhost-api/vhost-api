# frozen_string_literal: true
FactoryGirl.define do
  factory :dkimsigning, class: DkimSigning do
    author '@example.com'
    association :dkim, factory: :dkim, strategy: :create
    enabled true
  end
end
