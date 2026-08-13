class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit
  include Pundit
  allow_browser versions: :modern

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "Nuk jeni te autorizuar te beni ndryshime."
    redirect_to(request.referrer || root_path)
  end
end
