# Rails' file links (/rails/active_storage/...) don't go through ApplicationController,
# so by default anyone with a link could open a PDF without logging in.
# Included into ActiveStorage controllers by config/initializers/active_storage_access_control.rb
module ActiveStorageAccessControl
  # Every file link requires a logged-in user: others go to the login page,
  # and after login Devise sends them back to the file.
  # (Devise's authenticate_user! would answer a blank 401 for ".pdf" links.)
  module RequireLogin
    extend ActiveSupport::Concern

    included do
      before_action :require_login_for_files
    end

    private

    def require_login_for_files
      return if user_signed_in?

      store_location_for(:user, request.fullpath) if request.get?
      # ActiveStorage controllers don't have the app's route helpers, use them explicitly
      redirect_to Rails.application.routes.url_helpers.new_user_session_path,
                  alert: "Duhet të kyçeni për të hapur dokumentin."
    end
  end

  # Hidden ("deleted") PDFs, and all PDFs of archived (deleted) lawsuits,
  # open only for admin_developer, even from old links.
  # Runs after ActiveStorage::SetBlob has loaded @blob.
  module BlockHiddenFiles
    extend ActiveSupport::Concern

    included do
      before_action :block_hidden_files
    end

    private

    def block_hidden_files
      return if current_user&.admin_developer?

      attachments = @blob.attachments
      hidden_pdf = attachments.where(name: "deleted_pdf_files")
      archived_lawsuit_pdf = attachments.where(record_type: "Lawsuit", record_id: Lawsuit.discarded.select(:id))

      head :not_found if hidden_pdf.or(archived_lawsuit_pdf).exists?
    end
  end
end
