# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Dkim
class DkimPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for Dkim
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      dkims
    end

    private

    def dkims
      result = user.domains.dkims.all
      result.concat(user.customers.domains.dkims) if user.reseller?
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
end
