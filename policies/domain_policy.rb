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

  # Scope for Domain
  class Scope < Scope
    # @return [Array(Domain)]
    def resolve
      return scope.all if user.admin?
      domains
    end

    private

    def domains
      result = user.domains.all
      result.concat(user.customers.domains) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include :customer method
    class Admin < self
      # @return [Array]
      def attributes
        super << :customer
      end
    end

    class Reseller < Admin
    end

    # strip some stuff for User
    class User < Reseller
      # @return [Array]
      def attributes
        super - [:user_id, :customer]
      end
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    used_quota = user.domains.size
    used_quota += user.customers.domains.size if user.reseller?
    return true if used_quota < user.quota_domains
    false
  end
end
