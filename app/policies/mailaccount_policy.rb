# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
    used = check_account_storage
    available = user.packages.map(&:quota_mail_storage).reduce(0, :+)
    available - used
  end

  # Scope for MailAccount
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      mailaccounts
    end

    private

    def mailaccounts
      result = MailAccount.all(domain_id: user.domains.map(&:id))
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

  # rubocop:disable Metrics/AbcSize
  # @return [Boolean]
  def quotacheck(*requested_quota, update: false)
    unless requested_quota.blank?
      return false if requested_quota[0].zero?
      return false unless (storage_remaining - requested_quota[0]) >= 0
    end
    available_accounts = user.packages.map(&:quota_mail_accounts).reduce(0, :+)
    available_storage = user.packages.map(&:quota_mail_storage).reduce(0, :+)
    if update
      return true if check_account_num <= available_accounts &&
                     check_account_storage <= available_storage
    elsif check_account_num < available_accounts &&
          check_account_storage < available_storage
      return true
    end
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
    return false unless check_mailalias_set(params[:aliases])
    return false unless check_mailsource_set(params[:sources])
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
    if params.key?(:aliases)
      return false unless check_mailalias_set(params[:aliases])
    end
    if params.key?(:sources)
      return false unless check_mailsource_set(params[:sources])
    end
    if params.key?(:quota)
      return quotacheck(
        params[:quota] - record.quota, update: true
      )
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

  def check_mailalias_set(param)
    return true if param.nil?
    return true if mailalias_set.superset?(param.to_set)
    false
  end

  def mailalias_set
    return user_mailalias_set unless user.reseller?
    reseller_mailalias_set
  end

  def user_mailalias_set
    return user.domains.mail_aliases.map(&:id).to_set unless user.reseller?
    [].to_set
  end

  def reseller_mailalias_set
    if user.reseller?
      return user.domains.mail_aliases.map(&:id).concat(
        user.customers.domains.mail_aliases.map(&:id)
      ).to_set
    end
    [].to_Set
  end

  def check_mailsource_set(param)
    return true if param.nil?
    return true if mailsource_set.superset?(param.to_set)
    false
  end

  def mailsource_set
    return user_mailsource_set unless user.reseller?
    reseller_mailsource_set
  end

  def user_mailsource_set
    return user.domains.mail_sources.map(&:id).to_set unless user.reseller?
    [].to_set
  end

  def reseller_mailsource_set
    if user.reseller?
      return user.domains.mail_sources.map(&:id).concat(
        user.customers.domains.mail_sources.map(&:id)
      ).to_set
    end
    [].to_Set
  end
end
