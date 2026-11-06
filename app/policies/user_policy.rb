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
end
