# frozen_string_literal: true

require File.expand_path('application_policy.rb', __dir__)

# Policy for Shell
class ShellPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for Shell
  class Scope < Scope
    def resolve
      scope.all
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
    used = check_shelluser_num
    available = user.packages.map(&:quota_shell_users).reduce(0, :+)
    return true if used < available
    false
  end

  # @return [Fixnum]
  def check_shelluser_num
    shelluser_usage = user.vhosts.shell_users.size
    shelluser_usage += user.customers.vhosts.shell_users.size if user.reseller?
    shelluser_usage
  end
end
