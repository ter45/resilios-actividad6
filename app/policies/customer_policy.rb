class CustomerPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user&.admin? || user&.cashier? || user&.supervisor?
  end

  def new?
    create?
  end

  def update?
    user&.admin? || user&.supervisor?
  end

  def edit?
    update?
  end

  def destroy?
    user&.admin?
  end

  def toggle_active?
    user&.admin? || user&.supervisor?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin? || user&.supervisor?
        scope.all
      else
        scope.kept.where(active: true)
      end
    end
  end
end
