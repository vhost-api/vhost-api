# frozen_string_literal: true

require File.expand_path('application_policy.rb', __dir__)

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
  # rubocop:disable Metrics/AbcSize
  def show?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    return true if user.admin?
    return true if record.owner == user
    return true if user.packages.map(&:id).include?(record.id)
    false
  end
  # rubocop:enable Metrics/AbcSize

  # Checks if current user is allowed to update the record
  #
  # @return [Boolean]
  def update?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    return true if user.admin?
    return true if Package.all(user_id: user.id).map(&:id).include?(record.id)
    false
  end

  # Checks if current user is allowed to delete the record
  #
  # @return [Boolean]
  def destroy?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    return true if user.admin?
    return false unless record.users.empty?
    record.user_id == user.id
  end

  # Checks if current user is allowed to create a record with given params
  #
  # @return [Boolean]
  def create_with?(params)
    return true if user.admin?
    check_create_params(params)
  end

  # Checks if current user is allowed to update the record with given params
  #
  # @return [Boolean]
  def update_with?(params)
    return true if user.admin?
    check_update_params(params)
  end

  # Scope for Package
  class Scope < Scope
    def resolve
      return(scope.all) if user.admin?
      packages
    end

    private

    def packages
      result = scope.all(user_id: user.id)
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include :user relation
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
    return false unless user.reseller?
    used = Package.all(user_id: user.id).size
    available = user.packages.map(&:quota_custom_packages).reduce(0, :+)
    return true if used < available
    false
  end

  def check_create_params(params)
    return false unless user.reseller?
    return false unless quotacheck
    return true if params.key?(:user_id) && params[:user_id] == user.id
    false
  end

  # check amount of all assigned customers to a package before permission
  # rubocop:disable Metrics/AbcSize
  def check_update_params(params)
    return false unless user.reseller?
    params.each_pair do |k, v|
      next unless k.to_s =~ %r{^quota_}
      remaining = check_quota_prop(k)
      mult = record.users.size
      return false unless remaining >= ((v.to_i - record.send(k)) * mult)
    end
    true
  end
  # rubocop:enable Metrics/AbcSize

  def check_quota_prop(key)
    # call helper methods from quota_helper.rb
    count = reseller_allocated_quota(user, key)
    user.packages.map(&key).reduce(0, :+) - count
  end
end
