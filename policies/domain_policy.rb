class DomainPolicy < ApplicationPolicy
  class Scope < Scope
  end

  # def permitted_attributes
    # if user.admin?
      # [:name, :mail_enabled, :dns_enabled, :enabled]
    # else
      # [:name, :mail_enabled, :enabled]
    # end
  # end
end
