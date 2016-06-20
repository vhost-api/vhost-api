require File.expand_path '../application_policy.rb', __FILE__

class ApikeyPolicy < ApplicationPolicy
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
        @apikeys = scope.all(user_id: user.id)
        user.customers.each do |customer|
          customer.apikeys.each do |apikey|
            @apikeys.concat(scope.all(id: apikey.id))
          end
        end
        @apikeys
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
