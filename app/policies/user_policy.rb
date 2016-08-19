# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for User
class UserPolicy < ApplicationPolicy
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
    return true if record == user
    super
  end

  # Checks if current user is allowed to update the record
  #
  # @return [Boolean]
  def update?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    return true if record == user
    super
  end

  # Checks if current user is allowed to create a record with given params
  #
  # @return [Boolean]
  def create_with?(params)
    return true if user.admin?
    if params.key?(:group_id)
      return false unless check_group_id(params[:group_id])
    end
    check_create_params(params)
  end

  # Checks if current user is allowed to update the record with given params
  #
  # @return [Boolean]
  def update_with?(params)
    return true if user.admin?
    if params.key?(:id)
      return false unless check_id(params[:id])
    end
    if params.key?(:group_id)
      return false unless check_group_id(params[:group_id])
    end
    check_update_params(params)
  end

  # Checks if current user is allowed to delete the record
  #
  # @return [Boolean]
  def destroy?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    return true if record == user
    super
  end

  # Calculates remaining quota for <key>.
  #
  # @param key [Symbol]
  # @return [Fixnum]
  def remaining_quota(key)
    raise ArgumentError unless key.to_s =~ %r{^quota_}
    check_quota_prop(key)
  end

  # Scope for User
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      users
    end

    private

    def users
      result = scope.all(id: user.id)
      result.concat(user.customers) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include :group relation
    class Admin < self
      def attributes
        super.push(:group, :reseller, :packages)
      end
    end

    class Reseller < Admin
    end

    # Override for user
    class User < Reseller
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    return false unless user.reseller?
    used = user.customers.size
    available = user.packages.map(&:quota_customers).reduce(0, :+)
    return true if used < available
    false
  end

  # @return [Boolean]
  def check_create_params(params)
    return check_package_set(params[:packages].to_set) if params.key?(:packages)
    true
  end

  # @return [Boolean]
  def check_update_params(params)
    return check_package_set(params[:packages].to_set) if params.key?(:packages)
    true
  end

  def check_package_set(set)
    return false unless user.reseller?
    return true if reseller_package_set.superset?(set)
    false
  end

  def reseller_package_set
    return [].to_set unless user.reseller?
    Package.all(user_id: user.id).map(&:id).to_set
  end

  # @return [Fixnum]
  def check_quota_prop(key)
    prop = key.to_s[6..-1]
    # call helper methods from quota_helper.rb
    count = send("allocated_#{prop}", user)
    user.send(key) - count
  end

  # @return [Boolean]
  def check_id(id)
    return true if id == user.id
    false
  end

  # @return [Boolean]
  def check_group_id(group_id)
    return true if group_id == Group.first(name: 'user').id
    false
  end
end
