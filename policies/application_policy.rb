# frozen_string_literal: true
require File.expand_path '../application_policy.rb', __FILE__

# default application policy
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, 'You need to be logged in!' unless user
    @user = user
    @record = record
  end

  # Checks if current user is allowed to show the record
  #
  # @return [Boolean]
  def show?
    return true if user.admin?
    return true if user.reseller? && user.customers.include?(record.owner)
    return true if record.owner == user
    false
  end

  # Checks if current user is allowed to update the record
  #
  # @return [Boolean]
  def update?
    return true if user.admin?
    return true if user.reseller? && user.customers.include?(record.owner)
    return true if record.owner == user
    false
  end

  # Checks if current user is allowed to delete the record
  #
  # @return [Boolean]
  def destroy?
    return true if user.admin?
    return true if user.reseller? && user.customers.include?(record.owner)
    return true if record.owner == user
    false
  end

  # Checks if current user is allowed to create
  # new records of type record.class.
  # This method enforces the users quotas and prevents
  # creating more records than the user is allowed to.
  #
  # @return [Boolean]
  def create?
    # TODO: actual implementation including enforced quotas
    return true if user.admin?
    false
  end

  # default scope
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.all(user_id: user.id)
      end
    end
  end

  # default permissions
  class ApplicationPermissions
    attr_accessor :attributes, :errors
    attr_reader :record

    def initialize(record)
      @record = record
      @errors = []
    end

    def attributes
      record.properties.map(&:name)
    end
  end
end
