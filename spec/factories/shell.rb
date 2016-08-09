# frozen_string_literal: true
FactoryGirl.define do
  factory :shell, class: Shell do
    shell '/bin/bash'
    enabled true

    factory :invalid_shell do
      shell nil
    end
  end
end
