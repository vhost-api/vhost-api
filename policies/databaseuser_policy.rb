# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for DatabaseUser
class DatabaseUserPolicy < ApplicationPolicy
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

  # Scope for DatabaseUser
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      databaseusers
    end

    private

    def databaseusers
      result = user.database_users.all
      result.concat(user.customers.database_users) if user.reseller?
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
