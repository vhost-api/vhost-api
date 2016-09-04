# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for Ipv4Address
class Ipv4AddressPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Scope for Ipv4Address
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      ipv4addresses
    end

    private

    def ipv4addresses
      result = Ipv4Address.all(user_id: user.id)
      result.concat(user.customers.ipv4_addresses) if user.reseller?
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
