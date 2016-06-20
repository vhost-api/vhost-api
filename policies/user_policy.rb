require File.expand_path '../application_policy.rb', __FILE__

class UserPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        @users = scope.all(id: user.id)
        @users.concat(user.customers)
        @users
      else
        scope.all(id: user.id)
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
    end

    class Reseller < Admin
    end

    class User < Reseller
      def attributes
        super - [:group_id, :reseller_id]
      end
    end
  end
end
