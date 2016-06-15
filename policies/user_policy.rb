# frozen_string_literal; false
class UserPolicy < ApplicationPolicy
  # extend scope
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        user.customers
      else
        @users = scope.all(id: 0)
        @users.concat(scope.all(id: user.id))
        @users
      end
    end
  end
end
