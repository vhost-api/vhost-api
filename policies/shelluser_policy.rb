# frozen_string_literal; false
require File.expand_path '../application_policy.rb', __FILE__

class ShellUserPolicy < ApplicationPolicy
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
        @shellusers = scope.all(id: 0)
        user.vhosts.each do |vhost|
          @shellusers.concat(scope.all(vhost_id: vhost.id))
        end
        user.customers.each do |customer|
          customer.vhosts.each do |vhost|
            @shellusers.concat(scope.all(vhost_id: vhost.id))
          end
        end
        @shellusers
      else
        @shellusers = scope.all(id: 0)
        user.vhosts.each do |vhost|
          @shellusers.concat(scope.all(vhost_id: vhost.id))
        end
        @shellusers
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
