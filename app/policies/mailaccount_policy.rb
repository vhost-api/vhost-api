# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for MailAccount
class MailAccountPolicy < ApplicationPolicy
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

  # Calculates users remaining MailAccount storage quota.
  # Used when creating new MailAccounts.
  #
  # @return [Fixnum]
  def storage_remaining
    user.package.quota_mail_storage - check_account_storage
  end

  # Scope for MailAccount
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      mailaccounts
    end

    private

    def mailaccounts
      result = user.domains.mail_accounts.all
      result.concat(user.customers.domains.mail_accounts) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include some additional methods
    class Admin < self
      def attributes
        super.push(:domain,
                   :mail_aliases,
                   :mail_sources,
                   :customer,
                   :quotausage,
                   :quotausage_rel,
                   :sieveusage,
                   :sieveusage_rel)
      end
    end

    class Reseller < Admin
    end

    # strip method for User
    class User < Reseller
      def attributes
        super - [:customer]
      end
    end
  end

  private

  # @return [Boolean]
  def quotacheck(*requested_quota)
    unless requested_quota.blank?
      return false if storage_remaining < requested_quota[0]
    end
    return true if check_account_num < user.package.quota_mail_accounts &&
                   check_account_storage < user.package.quota_mail_storage
    false
  end

  # @return [Fixnum]
  def check_account_num
    acc_usage = user.domains.mail_accounts.size
    acc_usage += user.customers.domains.mail_accounts.size if user.reseller?
    acc_usage
  end

  # @return [Fixnum]
  def check_account_storage
    accounts = Pundit.policy_scope(user, MailAccount)
    accounts.map(&:quota).reduce(0, :+)
  end

  # @retun [Boolean]
  def check_create_params(params)
    return false unless check_domain_id(params[:domain_id])
    return quotacheck(params[:quota]) if params.key?(:quota)
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
    return quotacheck(params[:quota] - record.quota) if params.key?(:quota)
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
