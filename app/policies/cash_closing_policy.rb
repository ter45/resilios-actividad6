class CashClosingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
