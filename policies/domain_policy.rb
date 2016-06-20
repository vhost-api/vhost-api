require File.expand_path '../application_policy.rb', __FILE__

class DomainPolicy < ApplicationPolicy
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
        @domains = scope.all(user_id: user.id)
        user.customers.each do |customer|
          @domains.concat(customer.domains)
        end
        @domains
      else
        scope.all(user_id: user.id)
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
      def attributes
        super << :customer
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
      def attributes
        super - [:user_id, :customer]
      end
    end
  end
end
