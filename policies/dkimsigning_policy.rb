# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for DkimSigning
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

  # Scope for DkimSigning
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      dkimsignings
    end

    private

    def dkimsignings
      result = user.domains.dkims.dkim_signings.all
      if user.reseller?
        result.concat(user.customers.domains.dkims.dkim_signings)
      end
      result
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
