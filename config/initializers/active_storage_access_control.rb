# PDF links require login; hidden PDFs only for admin_developer.
# See app/controllers/concerns/active_storage_access_control.rb
Rails.application.config.to_prepare do
  # All file controllers: redirect, proxy and disk (the actual download)
  ActiveStorage::BaseController.include ActiveStorageAccessControl::RequireLogin

  # Controllers that receive a blob from a (never-expiring) signed link
  ActiveStorage::Blobs::RedirectController.include ActiveStorageAccessControl::BlockHiddenFiles
  ActiveStorage::Blobs::ProxyController.include ActiveStorageAccessControl::BlockHiddenFiles
end
