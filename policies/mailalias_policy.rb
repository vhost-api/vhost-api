# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for MailAlias
class MailAliasPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create
  # new records of type MailAlias.
  # This method enforces the users quotas and prevents
  # creating more records than the user is allowed to.
  #
  # @return [Boolean]
  def create?
    return true if user.admin?
    quotacheck
  end

  # Scope for MailAlias
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      mailaliases
    end

    private

    def mailaliases
      result = user.domains.mail_aliases.all
      result.concat(user.customers.domains.mail_aliases) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include destinations method
    class Admin < self
      def attributes
        super << :destinations
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
    return true if check_alias_num < user.quota_mail_aliases
    false
  end

  # @return [Fixnum]
  def check_alias_num
    alias_usage = user.domains.mail_aliases.size
    alias_usage += user.customers.domains.mail_aliases.size if user.reseller?
    alias_usage
  end
end
