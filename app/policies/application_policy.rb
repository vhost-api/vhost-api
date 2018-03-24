# frozen_string_literal: true

# default application policy
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise AuthenticationError unless user
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

  # Checks if current user is allowed to update the record with given params.
  # Needs to be implemented for each model individually.
  #
  # @return [Boolean]
  def update_with?(_params)
    false
  end

  # Checks if current user is allowed to delete the record
  #
  # @return [Boolean]
  def destroy?
    if record.is_a?(DataMapper::Resource)
      return false if record.destroyed?
    end
    destroy_check
  end

  # Checks if current user is allowed to create
  # new records of type record.class.
  # This method enforces the users quotas and prevents
  # creating more records than the user is allowed to.
  # The private quotacheck methods needs to be overridden
  # in model policies when needed.
  #
  # @return [Boolean]
  def create?
    return true if user.admin?
    quotacheck
  end

  # Checks if current user is allowed to create a record with given params
  # Needs to be implemented for each model individually.
  #
  # @return [Boolean]
  def create_with?(_params)
    false
  end

  # default scope
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Needs to be implemented for each model individually.
    def resolve
      false
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

    # rubocop:disable Lint/DuplicateMethods
    def attributes
      if record.is_a?(Array)
        record.properties.map(&:name)
      else
        record.class.properties.map(&:name)
      end
    end
    # rubocop:enable Lint/DuplicateMethods
  end

  private

  def quotacheck
    false
  end

  def destroy_check
    return true if user.admin?
    return true if user.reseller? && user.customers.include?(record.owner)
    return true if record.owner == user
    false
  end
end
