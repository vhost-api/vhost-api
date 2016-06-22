# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Shell
class ShellPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create
  # new records of type record.class.
  #
  # @return [Boolean]
  def create?
    return true if user.admin?
    false
  end

  # Scope for Shell
  class Scope < Scope
    def resolve
      scope.all
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
