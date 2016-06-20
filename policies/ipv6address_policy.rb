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

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        @ipv6addrs = scope.all(id: 0)
        @ipv6addrs.concat(user.ipv6_addresses)
        user.customers.each do |customer|
          customer.ipv6_addresses.each do |ipv6addr|
            @ipv6addrs.concat(scope.all(id: ipv6addr.id)) unless @ipv6addrs.include?(ipv6addr)
          end
        end
        @ipv6addrs
      else
        @ipv6addrs = scope.all(id: 0)
        @ipv6addrs.concat(user.ipv6_addresses)
        @ipv6addrs
      end
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
