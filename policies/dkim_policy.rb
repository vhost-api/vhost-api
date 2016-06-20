require File.expand_path '../application_policy.rb', __FILE__

class DkimPolicy < ApplicationPolicy
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
        @dkims = scope.all(id: 0)
        user.domains.each do |domain|
          @dkims.concat(scope.all(domain_id: domain.id))
        end
        user.customers.each do |customer|
          customer.domains.each do |domain|
            @dkims.concat(scope.all(domain_id: domain.id))
          end
        end
        @dkims
      else
        @dkims = scope.all(id: 0)
        user.domains.each do |domain|
          @dkims.concat(scope.all(domain_id: domain.id))
        end
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
