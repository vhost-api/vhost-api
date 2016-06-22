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
    # TODO: actual implementation including enforced quotas
    return true if user.admin?
    false
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
end
