# Base for everything under /admin.
# SECURITY: only admin_developer can access the Admin area.
module Admin
  class BaseController < ApplicationController
    before_action :require_admin_developer!

    private

    def require_admin_developer!
      return if current_user&.admin_developer?

      flash[:alert] = "Vetëm Admin Developer ka qasje në këtë faqe."
      redirect_to root_path
    end
  end
end
