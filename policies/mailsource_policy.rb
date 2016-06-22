# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for MailSource
class MailSourcePolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create
  # new records of type MailSource.
  # This method enforces the users quotas and prevents
  # creating more records than the user is allowed to.
  #
  # @return [Boolean]
  def create?
    return true if user.admin?
    quotacheck
  end

  # Scope for MailSource
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      mailsources
    end

    private

    def mailsources
      result = user.domains.mail_sources.all
      result.concat(user.customers.domains.mail_sources) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include allowed_from method
    class Admin < self
      def attributes
        super << :allowed_from
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
    return true if check_source_num < user.quota_mail_sources
    false
  end

  # @return [Fixnum]
  def check_source_num
    source_usage = user.domains.mail_sources.size
    source_usage += user.customers.domains.mail_sources.size if user.reseller?
    source_usage
  end
end
