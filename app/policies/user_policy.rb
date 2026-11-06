# User management: only admin_developer.
class UserPolicy < ApplicationPolicy
  def index?
    user.admin_developer?
  end

  def create?
    user.admin_developer?
  end

  def update?
    user.admin_developer?
  end

  # Activate / deactivate. Never your own account (no lockout).
  def toggle_active?
    user.admin_developer? && record.id != user.id
  end
end
