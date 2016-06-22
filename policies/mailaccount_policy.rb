# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for MailAccount
class MailAccountPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Calculates users remaining MailAccount storage quota.
  # Used when creating new MailAccounts.
  #
  # @return [Fixnum]
  def storage_remaining
    user.quota_mail_storage - check_account_storage
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
        super.push(:customer,
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
  def quotacheck
    return true if check_account_num < user.quota_mail_accounts &&
                   check_account_storage < user.quota_mail_storage
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
end
