require File.expand_path '../application_policy.rb', __FILE__

class MailAliasPolicy < ApplicationPolicy
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
        @mailaliases = scope.all(id: 0)
        user.domains.each do |domain|
          @mailaliases.concat(scope.all(domain_id: domain.id))
        end
        user.customers.each do |customer|
          customer.domains.each do |domain|
            @mailaliases.concat(scope.all(domain_id: domain.id))
          end
        end
        @mailaliases
      else
        @mailaliases = scope.all(domain_id: 0)
        user.domains.each do |domain|
          @mailaliases.concat(scope.all(domain_id: domain.id))
        end
        @mailaliases
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
      def attributes
        super << :destinations
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end
end
