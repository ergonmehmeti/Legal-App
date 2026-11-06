# Who hid which PDF of a lawsuit, when and why (reason visible to admin_developer only).
class PdfFileDeletion < ApplicationRecord
  has_paper_trail

  belongs_to :lawsuit
  belongs_to :attachment, class_name: "ActiveStorage::Attachment"
  belongs_to :deleted_by_user, class_name: "User"

  validates :reason, presence: true
end
