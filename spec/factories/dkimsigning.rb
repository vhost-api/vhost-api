# frozen_string_literal: true

FactoryBot.define do
  factory :dkimsigning, class: DkimSigning do
    author { 'example.com' }
    enabled { true }

    dkim_id do
      create(:dkim, selector: 'mail').id
    end

    factory :invalid_dkimsigning, parent: :dkimsigning do
      author { nil }
    end
  end
end
