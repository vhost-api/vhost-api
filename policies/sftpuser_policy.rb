require File.expand_path '../application_policy.rb', __FILE__

class SftpUserPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.reseller?
        @sftpusers = scope.all(id: 0)
        unless user.vhosts.nil? || user.vhosts.empty?
          user.vhosts.each do |vhost|
            @sftpusers.concat(scope.all(vhost_id: vhost.id))
          end
        end
        unless user.customers.nil? || user.customers.empty?
          user.customers.each do |customer|
            customer.vhosts.each do |vhost|
              @sftpusers.concat(scope.all(vhost_id: vhost.id))
            end
          end
        end
        @sftpusers
      else
        @sftpusers = scope.all(id: 0)
        unless user.vhosts.nil? || user.vhosts.empty?
          user.vhosts.each do |vhost|
            @sftpusers.concat(scope.all(vhost_id: vhost.id))
          end
        end
        @sftpusers
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
