# frozen_string_literal: true

require File.expand_path('application_policy.rb', __dir__)

# Policy for DkimSigning
class DkimSigningPolicy < ApplicationPolicy
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

  # Scope for DkimSigning
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      dkimsignings
    end

    private

    def dkimsignings
      result = DkimSigning.all(dkim_id: user.domains.dkims.map(&:id))
      if user.reseller?
        result.concat(user.customers.domains.dkims.dkim_signings)
      end
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include some additional methods
    class Admin < self
      def attributes
        super.push(:dkim)
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
    return false unless check_dkim_id(params[:dkim_id])
    true
  end

  # @retun [Boolean]
  def check_update_params(params)
    if params.key?(:id)
      return false unless check_id(params[:id])
    end
    if params.key?(:dkim_id)
      return false unless check_dkim_id(params[:dkim_id])
    end
    true
  end

  def check_id(id)
    return true if id == record.id
    false
  end

  def check_dkim_id(dkim_id)
    return true if user.domains.dkims.map(&:id).include?(dkim_id)
    return true if user.reseller? && user.customers.domains.dkims.map(
      &:id
    ).include?(
      dkim_id
    )
    false
  end
end
