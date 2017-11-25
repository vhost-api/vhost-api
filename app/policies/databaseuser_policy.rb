# frozen_string_literal: true

require File.expand_path '../application_policy.rb', __FILE__

# Policy for DatabaseUser
class DatabaseUserPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for DatabaseUser
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      databaseusers
    end

    private

    def databaseusers
      result = DatabaseUser.all(user_id: user.id)
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

  private

  # @return [Boolean]
  def quotacheck
    available = user.packages.map(&:quota_database_users).reduce(0, :+)
    return true if check_dbuser_num < available
    false
  end

  # @return [Fixnum]
  def check_dbuser_num
    dbuser_usage = user.database_users.size
    dbuser_usage += user.customers.database_users.size if user.reseller?
    dbuser_usage
  end
end
