# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Package
class PackagePolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to show the record
  #
  # @return [Boolean]
  def show?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    super
  end

  # Checks if current user is allowed to update the record
  #
  # @return [Boolean]
  def update?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    super
  end

  # Checks if current user is allowed to delete the record
  #
  # @return [Boolean]
  def destroy?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    super
  end

  # Scope for Package
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      packages
    end

    private

    def packages
      scope.all(user_id: user.id)
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
