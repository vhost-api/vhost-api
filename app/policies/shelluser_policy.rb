# frozen_string_literal: true

require File.expand_path('application_policy.rb', __dir__)

# Policy for ShellUser
class ShellUserPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for ShellUser
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      shellusers
    end

    private

    def shellusers
      result = ShellUser.all(vhost_id: user.vhosts.map(&:id))
      result.concat(user.customers.vhosts.shell_users) if user.reseller?
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
    return true if check_shelluser_num < user.quota_shell_users
    false
  end

  # @return [Fixnum]
  def check_shelluser_num
    shelluser_usage = user.vhosts.shell_users.size
    shelluser_usage += user.customers.vhosts.shell_users.size if user.reseller?
    shelluser_usage
  end
end
