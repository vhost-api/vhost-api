class Ipv4AddressPolicy < ApplicationPolicy
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
        @ipv4addrs = scope.all(id: 0)
        @ipv4addrs.concat(user.ipv4_addresses)
        user.customers.each do |customer|
          customer.ipv4_addresses.each do |ipv4addr|
            @ipv4addrs.concat(scope.all(id: ipv4addr.id)) unless @ipv4addrs.include?(ipv4addr)
          end
        end
        @ipv4addrs
      else
        @ipv4addrs = scope.all(id: 0)
        @ipv4addrs.concat(user.ipv4_addresses)
        @ipv4addrs
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
