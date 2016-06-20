require File.expand_path '../application_policy.rb', __FILE__

class DkimSigningPolicy < ApplicationPolicy
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
        @dkimsignings = scope.all(id: 0)
        user.domains.each do |domain|
          domain.dkims.each do |dkim|
            @dkimsignings.concat(scope.all(dkim_id: dkim.id))
          end
        end
        user.customers.each do |customer|
          customer.domains.each do |domain|
            domain.dkims.each do |dkim|
              @dkimsignings.concat(scope.all(dkim_id: dkim.id))
            end
          end
        end
        @dkimsignings
      else
        @dkimsignings = scope.all(id: 0)
        user.domains.each do |domain|
          domain.dkims.each do |dkim|
            @dkimsignings.concat(scope.all(dkim_id: dkim.id))
          end
        end
        @dkimsignings
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
