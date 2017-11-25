# frozen_string_literal: true

require File.expand_path '../application_policy.rb', __FILE__

# Policy for SshPubkey
class SshPubkeyPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for SshPubkey
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      sshpubkeys
    end

    private

    def sshpubkeys
      result = SshPubkey.all(user_id: user.id)
      result.concat(user.customers.ssh_pubkeys) if user.reseller?
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
    sshpubkey_quota = user.ssh_pubkeys.size
    sshpubkey_quota += user.customers.ssh_pubkeys.size if user.reseller?
    return true if sshpubkey_quota < user.quota_ssh_pubkeys
    false
  end
end
