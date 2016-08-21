# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# Policy for MailForwarding
class MailForwardingPolicy < ApplicationPolicy
  def permitted_attributes
    return Permissions::Admin.new(record).attributes if user.admin?
    return Permissions::Reseller.new(record).attributes if user.reseller?
    Permissions::User.new(record).attributes
  end

  # Checks if current user is allowed to create a record with given params
  #
  # @return [Boolean]
  def create_with?(params)
    return true if user.admin?
    check_create_params(params)
  end

  # Checks if current user is allowed to update the record with given params
  #
  # @return [Boolean]
  def update_with?(params)
    return true if user.admin?
    check_update_params(params)
  end

  # Scope for MailForwarding
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      mailaliases
    end

    private

    def mailaliases
      result = user.domains.mail_aliases.all
      result.concat(user.customers.domains.mail_aliases) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include destinations method
    class Admin < self
      def attributes
        super.push(:domain)
      end
    end

    class Reseller < Admin
    end

    class User < Reseller
    end
  end

  private

  # @return [Boolean]
  def quotacheck
    available = user.packages.map(&:quota_mail_forwardings).reduce(0, :+)
    return true if check_forwarding_num < available
    false
  end

  # @return [Fixnum]
  def check_forwarding_num
    forwarding_usage = forwarding_num(user, nil)
    forwarding_usage += forwarding_num(nil, user.customers) if user.reseller?
    forwarding_usage
  end

  def forwarding_num(user = nil, users = nil)
    forwardings = if user.nil? && !users.nil?
                    users.domains.mail_forwardings
                  else
                    user.domains.mail_forwardings
                  end
    forwardings.map(&:destinations).join("\n").split("\n").size
  end

  # @retun [Boolean]
  def check_create_params(params)
    return false unless check_domain_id(params[:domain_id])
    true
  end

  # @retun [Boolean]
  def check_update_params(params)
    if params.key?(:id)
      return false unless check_id(params[:id])
    end
    if params.key?(:domain_id)
      return false unless check_domain_id(params[:domain_id])
    end
    true
  end

  def check_id(id)
    return true if id == record.id
    false
  end

  def check_domain_id(domain_id)
    return true if user.domains.map(&:id).include?(domain_id)
    return true if user.reseller? && user.customers.domains.map(&:id).include?(
      domain_id
    )
    false
  end
end
