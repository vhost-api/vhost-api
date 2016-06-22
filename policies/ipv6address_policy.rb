# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Ipv6Address
class Ipv6AddressPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create
  # new records of type record.class.
  #
  # @return [Boolean]
  def create?
    return true if user.admin?
    false
  end

  # Scope for Ipv6Address
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      ipv6addresses
    end

    private

    def ipv6addresses
      result = user.ipv6_addresses.all
      result.concat(user.customers.ipv6_addresses) if user.reseller?
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
