# frozen_string_literal: true
# default application policy
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, 'You need to be logged in!' unless user
    @user = user
    @record = record
  end

  def update?
    user.admin? || user.owner_of?(record)
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
end
