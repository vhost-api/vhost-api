# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Vhost
class VhostPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Calculates users remaining Vhost storage quota.
  # Used when creating new Vhosts.
  #
  # @return [Fixnum]
  def storage_remaining
    user.quota_vhost_storage - check_vhost_storage
  end

  # Scope for Vhost
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      vhosts
    end

    private

    def vhosts
      result = Vhost.all(user_id: user.id)
      result.concat(user.customers.vhosts) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    class Admin < self
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    return true if check_vhost_num < user.quota_vhosts &&
                   check_vhost_storage < user.quota_vhost_storage
    false
  end

  # @return [Fixnum]
  def check_vhost_num
    vhost_usage = user.vhosts.size
    vhost_usage += user.customers.vhosts.size if user.reseller?
    vhost_usage
  end

  # @return [Fixnum]
  def check_vhost_storage
    vhosts = Pundit.policy_scope(user, Vhost)
    vhosts.map(&:quota).reduce(0, :+)
  end
end
