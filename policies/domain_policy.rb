# frozen_string_literal; false
class DomainPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record.first).attributes if user.admin?
    return Permissions::Reseller.new(record.first).attributes if user.reseller?
    Permissions::User.new(record.first).attributes
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        @domains = scope.all(id: 0)
        user.customers.each do |customer|
          @domains.concat(customer.domains)
        end
        @domains
      else
        @domains = scope.all(id: 0)
        @domains.concat(user.domains)
        @domains
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
    end

    class Reseller < Admin
      def attributes
        super - [:id, :created_at, :updated_at]
      end
    end

    class User < Reseller
      def attributes
        super - [:user_id]
      end
    end
  end
end
