class LawsuitPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  # Which lawsuits a user may see at all. Every list / lookup of lawsuits goes through
  # policy_scope(Lawsuit), so a legal representative never sees lawsuits that aren't theirs.
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.legal_representative?
        # Assigned lawsuits + every lawsuit of their category scopes (User#category_scopes).
        assigned = scope.represented_by(user)
        user.category_scopes.any? ? assigned.or(scope.where(category: user.category_scopes)) : assigned
      else
        scope
      end
    end
  end

  # Seeing a lawsuit: the scope above does the filtering (lookups go through it)
  def index?
    true
  end

  def show?
    true
  end

  # Create: everyone except legal representatives (operators may create, not edit)
  def create?
    !user.legal_representative?
  end

  def update?
    # Only admins edit lawsuits. Listed explicitly (not "!operator?") so that new roles,
    # like legal_representative, can't edit by default.
    user.admin? || user.admin_developer?
  end

  def destroy?
    # Both admin and admin_developer can delete lawsuits
    user.admin? || user.admin_developer?
  end

  # Adding comments: everyone except legal representatives (view only, for now)
  def comment?
    !user.legal_representative?
  end

  # Choosing the legal representatives of a lawsuit (in the lawsuit form)
  def assign_representatives?
    user.admin? || user.admin_developer?
  end

  # "Lëndët e Mia" page (all categories, only lawsuits where the user is a representative).
  # A legal representative doesn't need it: their whole app already shows only their lawsuits.
  def mine?
    user.admin? || user.operator?
  end

  # History of who was representative and when (lawsuit page): admins only
  def view_representative_history?
    user.admin? || user.admin_developer?
  end

  def view_deleted?
    # Only admin_developer can view deleted lawsuits
    user.admin_developer?
  end

  # PDFs: whoever can edit the lawsuit can delete (hide) a PDF
  def destroy_pdf?
    update?
  end

  # Only admin_developer sees hidden PDFs (with reason) and can restore them
  def view_deleted_pdfs?
    user.admin_developer?
  end

  def restore_pdf?
    user.admin_developer?
  end

end
