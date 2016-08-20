# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Database
class DatabasePolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for Database
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      databases
    end

    private

    def databases
      result = user.databases.all
      result.concat(user.customers.databases) if user.reseller?
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
    db_num = user.databases.size
    db_num += user.customers.databases.size if user.reseller?
    available = user.packages.map(&:quota_databases).reduce(0, :+)
    return true if db_num < available
    false
  end
end
