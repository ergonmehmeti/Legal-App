class LawsuitPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end
  end
  def update?
    !user.operator? # Only non-operators can update lawsuits
  end

  def destroy?
    # Both admin and admin_developer can delete lawsuits
    user.admin? || user.admin_developer?
  end
  
  def view_deleted?
    # Only admin_developer can view deleted lawsuits
    user.admin_developer?
  end

end
