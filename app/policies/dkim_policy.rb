# frozen_string_literal: true

require File.expand_path '../application_policy.rb', __FILE__

# Policy for Dkim
class DkimPolicy < ApplicationPolicy
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
    check_create_params(params)
  end

  # Checks if current user is allowed to update the record with given params
  #
  # @return [Boolean]
  def update_with?(params)
    return true if user.admin?
    check_update_params(params)
  end

  # Scope for Dkim
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      dkims
    end

    private

    def dkims
      result = Dkim.all(domain_id: user.domains.map(&:id))
      result.concat(user.customers.domains.dkims) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include some additional methods
    class Admin < self
      def attributes
        super.push(:domain,
                   :dkim_signings)
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end

  private

  def quotacheck
    true
  end

  # @retun [Boolean]
  def check_create_params(params)
    return false unless check_domain_id(params[:domain_id])
    true
  end

  # @retun [Boolean]
  def check_update_params(params)
    if params.key?(:id)
      return false unless check_id(params[:id])
    end
    if params.key?(:domain_id)
      return false unless check_domain_id(params[:domain_id])
    end
    true
  end

  def check_id(id)
    return true if id == record.id
    false
  end

  def check_domain_id(domain_id)
    return true if user.domains.map(&:id).include?(domain_id)
    return true if user.reseller? && user.customers.domains.map(&:id).include?(
      domain_id
    )
    false
  end
end
