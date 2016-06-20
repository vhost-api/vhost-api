require File.expand_path '../application_policy.rb', __FILE__

class MailAccountPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  def show?
    return true if user.admin?
    return true if user.reseller? && user.customers.include?(record.owner)
    return true if record.owner == user
    false
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        @mailaccounts = scope.all(id: 0)
        user.domains.each do |domain|
          @mailaccounts.concat(scope.all(domain_id: domain.id))
        end
        user.customers.each do |customer|
          customer.domains.each do |domain|
            @mailaccounts.concat(scope.all(domain_id: domain.id))
          end
        end
        @mailaccounts
      else
        @mailaccounts = scope.all(domain_id: 0)
        user.domains.each do |domain|
          @mailaccounts.concat(scope.all(domain_id: domain.id))
        end
        @mailaccounts
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
      def attributes
        super.push(:customer,
                   :quotausage,
                   :quotausage_rel,
                   :sieveusage,
                   :sieveusage_rel)
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
      def attributes
        super - [:customer]
      end
    end
  end
end
