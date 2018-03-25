# frozen_string_literal: true

require File.expand_path('application_policy.rb', __dir__)

# Policy for MailAlias
class MailAliasPolicy < ApplicationPolicy
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

  # Scope for MailAlias
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      mailaliases
    end

    private

    def mailaliases
      result = MailAlias.all(domain_id: user.domains.map(&:id))
      result.concat(user.customers.domains.mail_aliases) if user.reseller?
      result
    end
  end

  class Permissions < ApplicationPermissions
    # include destinations method
    class Admin < self
      def attributes
        super.push(:domain,
                   :mail_accounts)
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
    available = user.packages.map(&:quota_mail_aliases).reduce(0, :+)
    return true if check_alias_num < available
    false
  end

  # @return [Fixnum]
  def check_alias_num
    alias_usage = user.domains.mail_aliases.size
    alias_usage += user.customers.domains.mail_aliases.size if user.reseller?
    alias_usage
  end

  # @retun [Boolean]
  def check_create_params(params)
    return false unless check_domain_id(params[:domain_id])
    return false unless check_mailaccount_set(params[:dest].to_set)
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
    return check_mailaccount_set(params[:dest].to_set) if params.key?(:dest)
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

  def check_mailaccount_set(set)
    return true if mailaccount_set.superset?(set)
    false
  end

  def mailaccount_set
    return user_mailaccount_set unless user.reseller?
    reseller_mailaccount_set
  end

  def user_mailaccount_set
    return user.domains.mail_accounts.map(&:id).to_set unless user.reseller?
    [].to_set
  end

  def reseller_mailaccount_set
    if user.reseller?
      return user.domains.mail_accounts.map(&:id).concat(
        user.customers.domains.mail_accounts.map(&:id)
      ).to_set
    end
    [].to_Set
  end
end
