# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Domain
class DomainPolicy < ApplicationPolicy
  # @return [Array]
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

  # Scope for Domain
  class Scope < Scope
    # @return [Array(Domain)]
    def resolve
      return scope.all if user.admin?
      domains
    end

    private

    def domains
      result = user.domains.all
      result.concat(user.customers.domains) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include :customer method
    class Admin < self
      # @return [Array]
      def attributes
        super << :customer
      end
    end

    class Reseller < Admin
    end

    # strip some stuff for User
    class User < Reseller
      # @return [Array]
      def attributes
        super - [:user_id, :customer]
      end
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    used_quota = user.domains.size
    used_quota += user.customers.domains.size if user.reseller?
    return true if used_quota < user.quota_domains
    false
  end

  def check_id(id)
    return true if id == record.id
    false
  end

  def check_user_id(user_id)
    return true if user_id == user.id
    return true if user.reseller? && user.customers.include?(
      User.get(user_id)
    )
    false
  end
end
