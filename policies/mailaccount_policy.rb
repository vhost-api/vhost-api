# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for MailAccount
class MailAccountPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create
  # new records of type MailAccount.
  # This method enforces the users quotas and prevents
  # creating more records than the user is allowed to.
  #
  # @return [Boolean]
  def create?
    return true if user.admin?
    quotacheck
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
    used_quota = user.domains.mail_accounts.size
    used_quota += user.customers.domains.mail_accounts.size if user.reseller?
    return true if used_quota < user.quota_mail_accounts
    false
  end
end
