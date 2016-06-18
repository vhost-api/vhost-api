# frozen_string_literal; false
require File.expand_path '../application_policy.rb', __FILE__

class AliasVhostPolicy < ApplicationPolicy
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
        @aliasvhosts = scope.all(user_id: user.id)
        user.customers.each do |customer|
          customer.alias_vhosts.each do |aliasvhost|
            @aliasvhosts.concat(scope.all(id: aliasvhost.id))
          end
        end
        @aliasvhosts
      else
        scope.all(user_id: user.id)
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end
end
