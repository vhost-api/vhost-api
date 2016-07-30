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
    if params.key?(:user_id)
      result_uid = check_user_id(params[:user_id])
      return false unless result_uid
    end
    true
  end

  # Checks if current user is allowed to update the record with given params
  #
  # @return [Boolean]
  def update_with?(params)
    return true if user.admin?
    if params.key?(:id)
      result_id = check_id(params[:id])
      return false unless result_id
    end
    if params.key?(:user_id)
      result_uid = check_user_id(params[:user_id])
      return false unless result_uid
    end
    true
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
    class Admin < self
    end

    class Reseller < Admin
    end

    # Override for user
    class User < Reseller
      def attributes
        super - [:group_id, :reseller_id]
      end
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    return false unless user.reseller?
    customer_quota = user.customers.size
    return true if customer_quota < user.quota_customers
    false
  end

  # @return [Boolean]
  def check_id(id)
    return true if id == user.id
    false
  end

  # @return [Boolean]
  def check_group_id(group_id)
    return true if group_id == user.group_id
    false
  end
end
