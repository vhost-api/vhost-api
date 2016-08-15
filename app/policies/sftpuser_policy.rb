# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for SftpUser
class SftpUserPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for SftpUser
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      sftpusers
    end

    private

    # @return [Array(SftpUser)]
    def sftpusers
      result = user.vhosts.sftp_users.all
      result.concat(user.customers.vhosts.sftp_users) if user.reseller?
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
    return true if check_sftpuser_num < user.package.quota_sftp_users
    false
  end

  # @return [Fixnum]
  def check_sftpuser_num
    sftpuser_usage = user.vhosts.sftp_users.size
    sftpuser_usage += user.customers.vhosts.sftp_users.size if user.reseller?
    sftpuser_usage
  end
end
