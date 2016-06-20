require File.expand_path '../application_policy.rb', __FILE__

class MailSourcePolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create
  # new records of type record.class.
  # This method enforces the users quotas and prevents
  # creating more records than the user is allowed to.
  #
  # @return [Boolean]
  def create?
    # TODO: actual implementation including enforced quotas
    return true if user.admin?
    false
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        @mailsources = scope.all(id: 0)
        user.domains.each do |domain|
          @mailsources.concat(scope.all(domain_id: domain.id))
        end
        user.customers.each do |customer|
          customer.domains.each do |domain|
            @mailsources.concat(scope.all(domain_id: domain.id))
          end
        end
        @mailsources
      else
        @mailsources = scope.all(domain_id: 0)
        user.domains.each do |domain|
          @mailsources.concat(scope.all(domain_id: domain.id))
        end
        @mailsources
      end
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
      def attributes
        super << :allowed_from
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end
end
