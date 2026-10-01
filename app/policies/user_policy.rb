class UserPolicy < ApplicationPolicy
  def index?
    user&.active? && user.admin?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.active? && user.admin? ? scope.all : scope.none
    end
  end
end
