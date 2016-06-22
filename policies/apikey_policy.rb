# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for ApiKey
class ApikeyPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for Apikey
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      apikeys
    end

    private

    def apikeys
      result = user.apikeys.all
      result.concat(user.customers.apikeys) if user.reseller?
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
    apikey_quota = user.apikeys.size
    apikey_quota += user.customers.apikeys.size if user.reseller?
    return true if apikey_quota < user.quota_apikeys
    false
  end
end
