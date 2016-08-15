# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for ApiKey
class ApikeyPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create a record with given params
  #
  # @return [Boolean]
  def create_with?(params)
    return true if user.admin?
    return check_user_id(params[:user_id]) if params.key?(:user_id)
    true
  end

  # Checks if current user is allowed to update the record with given params
  #
  # @return [Boolean]
  def update_with?(params)
    return true if user.admin?
    if params.key?(:id)
      return false unless check_id(params[:id])
    end
    if params.key?(:user_id)
      return false unless check_user_id(params[:user_id])
    end
    true
  end

  # Scope for Apikey
  class Scope < Scope
    # @return [Array(Apikey)]
    def resolve
      return scope.all if user.admin?
      apikeys
    end

    private

    # @return [Array(Apikey)]
    def apikeys
      result = user.apikeys.all
      result.concat(user.customers.apikeys) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include some additional methods
    class Admin < self
      def attributes
        super.push(:user)
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    apikey_quota = user.apikeys.size
    apikey_quota += user.customers.apikeys.size if user.reseller?
    return true if apikey_quota < user.package.quota_apikeys
    false
  end

  # @return [Boolean]
  def check_id(id)
    return true if id == record.id
    false
  end

  # @return [Boolean]
  def check_user_id(user_id)
    return true if user_id == user.id
    return true if user.reseller? && user.customers.include?(
      User.get(user_id)
    )
    false
  end
end
