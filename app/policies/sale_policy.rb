class SalePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def void?
    user&.admin? || user&.supervisor?
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
