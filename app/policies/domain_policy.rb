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

  # Scope for Domain
  class Scope < Scope
    # @return [Array(Domain)]
    def resolve
      return scope.all if user.admin?
      domains
    end

    private

    # @return [Array(Domain)]
    def domains
      result = Domain.all(user_id: user.id)
      result.concat(user.customers.domains) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include :customer method
    class Admin < self
      # @return [Array]
      def attributes
        super << :user
      end
    end

    class Reseller < Admin
    end

    # strip some stuff for User
    class User < Reseller
      # @return [Array]
      def attributes
        super
      end
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    used_quota = user.domains.size
    used_quota += user.customers.domains.size if user.reseller?
    available = user.packages.map(&:quota_domains).reduce(0, :+)
    return true if used_quota < available
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
