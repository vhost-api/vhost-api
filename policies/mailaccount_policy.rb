# frozen_string_literal; false
class MailAccountPolicy < ApplicationPolicy
  # extend scope
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        @mailaccounts = scope.all(domain_id: 0)
        user.domains.each do |domain|
          @mailaccounts.concat(scope.all(domain_id: domain.id))
        end
        @mailaccounts
      end
    end
  end
end
