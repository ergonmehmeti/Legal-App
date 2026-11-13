class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit
  include Pundit
  allow_browser versions: :modern

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :visible_categories

  private

  def user_not_authorized
    flash[:alert] = "Nuk jeni te autorizuar te beni ndryshime."
    redirect_to(request.referrer || root_path)
  end

  # Categories the current user may open ({ key => "Label" }, same format as Lawsuit.categories).
  # Everyone sees all of them, except a legal representative: only categories in which
  # they have at least one (non-archived) lawsuit. Used by the navbar, home and lawsuits list.
  def visible_categories
    @visible_categories ||=
      if current_user&.legal_representative?
        # + their category scopes, even while such a category has no lawsuits yet
        used = policy_scope(Lawsuit).kept.distinct.pluck(:category) | current_user.category_scopes
        Lawsuit.categories.select { |key, _| used.include?(key) }
      else
        Lawsuit.categories
      end
  end

  # For pages a legal representative must not open at all (Provizionimet, CSV export, ...)
  def block_legal_representative
    return unless current_user&.legal_representative?

    redirect_to root_path, alert: "Nuk keni qasje në këtë faqe."
  end
end
